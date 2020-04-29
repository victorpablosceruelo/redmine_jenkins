require 'logger'
require 'net/http'
require 'json'
require 'base64'

module JenkinsJobs
  class Base

    include Redmine::I18n

    attr_reader :jenkins_job
    attr_reader :job_data
    attr_reader :errors
    attr_reader :use_case


    def initialize(jenkins_job, logger)
      @jenkins_job = jenkins_job
      @job_data    = nil
      @errors      = []
      @use_case    = self.class.name.split('::').last.underscore

      if (nil == logger)
	@log_location = STDOUT unless @log_location
	@log_level = Logger::INFO unless @log_level
	@logger = Logger.new(@log_location)
	@logger.level = @log_level
      else 
	@logger = logger
      end
    end


    def call(*args, &block)
      self.send(:execute, *args, &block)
      return self
    end


    def jenkins_client
      jenkins_job.jenkins_connection
    end


    def success?
      errors.empty?
    end


    def errors
      @errors.uniq
    end


    def message_on_success
      l("use_cases.jenkins_job.#{use_case}.success", jenkins_job: jenkins_job.to_s)
    end


    def message_on_errors
      l("use_cases.jenkins_job.#{use_case}.failed", jenkins_job: jenkins_job.to_s, errors: errors.to_sentence)
    end


    private


      def job_status_updated?
        get_jenkins_job_details
        return false if job_data.nil?
        update_job_status
      end


      def update_job_status
        jenkins_job.state                 = color_to_state(job_data['color']) || jenkins_job.state
        jenkins_job.state_color            = job_data['color'] || jenkins_job.state_color
        jenkins_job.description           = job_data['description'] || ''
        jenkins_job.health_report         = job_data['healthReport']
        jenkins_job.latest_build_number   = !job_data['lastBuild'].nil? ? job_data['lastBuild']['number'] : 0
        jenkins_job.latest_build_date     = jenkins_job.builds.last.finished_at rescue ''
        jenkins_job.latest_build_duration = jenkins_job.builds.last.duration rescue ''
        jenkins_job.sonarqube_dashboard_url = ''
        jenkins_job.save!
        jenkins_job.reload
        true
      end

      def do_create_builds(builds, update = false)
        builds.reverse.each do |build_data|
          ## Find Build in Redmine
          jenkins_build = jenkins_job.builds.find_by_number(build_data['number'])

          if jenkins_build.nil?
            create_build(build_data['number'])
          elsif !jenkins_build.nil? && update
            update_build(jenkins_build, build_data['number'])
          end
        end

	update_sonarqube_metrics_if_possible()

        clean_up_builds
	return true
      end


      def create_build(build_number)
        ## Get BuildDetails from Jenkins
        build_details = get_jenkins_build_details(build_number)
	# @logger.info "build_details: '#{build_details}'"

        ## Create a new AR object to store data
        build = jenkins_job.builds.new
        build.number      = build_number
        build.result      = build_details['result'].nil? ? 'running' : build_details['result']
        build.building    = build_details['building']
        build.duration    = build_details['duration']
        build.finished_at = Time.at(build_details['timestamp'].to_f / 1000)
        build.author      = User.current
        build.save!

        ## Update changesets
        create_changeset_if_possible(build, build_details)

        ## Update SonarqubeDashboardUrl
        getSonarqubeDashboardUrl(build_details)

	# Not for every build, please ... 
        # update_sonarqube_metrics_if_possible()

      end


      def update_build(build, build_number)
        @logger.info "update_build: Updating build information for build number '#{build_number}'"

        ## Get BuildDetails from Jenkins
        build_details = get_jenkins_build_details(build_number)

        # @logger.info "update_build: build_details: '#{build_details}'"

        ## Update the AR object with new data
        build.result      = build_details['result'].nil? ? 'running' : build_details['result']
        build.building    = build_details['building']
        build.duration    = build_details['duration']
        build.finished_at = Time.at(build_details['timestamp'].to_f / 1000)
        build.save!

        ## Update changesets. 
        create_changeset_if_possible(build, build_details)

        ## Update SonarqubeDashboardUrl
        getSonarqubeDashboardUrl(build_details)

        update_sonarqube_metrics_if_possible()

      end

      def create_changeset_if_possible(build, build_details)
        ## Update changesets. Be careful: sometimes the answer does not have them ... 
        if (build_details['changeSet'] == nil)
          errorMsg = "Could not create changeSet: changeSet not available in Jenkins response. \n"
          @logger.warn errorMsg
          # @errors << errorMsg
          @logger.debug "Jenkins response: #{build_details} "
        else
          changeSet = build_details['changeSet']
          if (changeSet['items'] == nil)
            errorMsg = "Could not create changeSet: changeSetItems not available in Jenkins response. \n"
            @logger.warn errorMsg
            # @errors << errorMsg
            @logger.debug "Jenkins response: #{build_details} "
          else
            changeSetItems = changeSet['items']
            create_changeset(build, changeSetItems)
          end
        end
      end


      def getSonarqubeDashboardUrl(build_details)
        begin
          @logger.debug "build_details: #{build_details} "

          build_details.each do |key, build_detail_array|
            sonarqube_dashboard_url = getSonarqubeDashboardUrlAux(key, build_detail_array)
            if (! ('' == sonarqube_dashboard_url))
              @logger.info "sonarqubeDashboardUrl: '#{sonarqube_dashboard_url}'"
              jenkins_job.sonarqube_dashboard_url = sonarqube_dashboard_url
              jenkins_job.save!
              jenkins_job.reload
              return sonarqube_dashboard_url
            end
          end
        rescue => e
          errorMsg = "getSonarqubeDashboardUrl: #{e.message} " 
          @errors << errorMsg
          @logger.error errorMsg
          @logger.error e.backtrace.join("\n")
        end
        return ''
      end


      def getSonarqubeDashboardUrlAux(key, build_detail_array)
        begin
          if (! (key == nil)) && (key == 'actions')
            # @logger.info "build_detail_array: '#{build_detail_array}'"
            build_detail_array.each do |build_detail|
              # @logger.info "build_detail: '#{build_detail}'"
              if ((! (build_detail == nil)) && (! (build_detail['_class'] == nil)))
                if (build_detail['_class'] == 'hudson.plugins.sonar.action.SonarAnalysisAction')
                  sonarqube_dashboard_url = build_detail['sonarqubeDashboardUrl']
                  @logger.info "sonarqubeDashboardUrl: '#{sonarqube_dashboard_url}'"
                  return sonarqube_dashboard_url
                end
              end
            end
          end 
        rescue => e
          errorMsg = "getSonarqubeDashboardUrlAux: #{e.message} "
          @errors << errorMsg
          @logger.error errorMsg
          @logger.error e.backtrace[0]
          @logger.error "build_detail_array: "
          @logger.error build_detail_array
        end
        return ''
      end

      def update_sonarqube_metrics_if_possible()
        if ('' == jenkins_job.sonarqube_dashboard_url)
          @logger.info "update_sonarqube_metrics_if_possible: Not possible when url is invalid in jenkins_job.sonarqube_dashboard_url."
          return
        end
        @logger.info "update_sonarqube_metrics_if_possible: sonarqubeDashboardUrl: '#{jenkins_job.sonarqube_dashboard_url}'"

	response_body = nil
        begin
          sonarqube_api_url = jenkins_job.sonarqube_dashboard_url
	  if sonarqube_api_url.nil?
		  raise RedmineJenkins::Error::JenkinsConnectionError, 'No SonarQube url available. Could not retrieve metrics.'
	  end
          sonarqube_api_url = sonarqube_api_url.gsub("dashboard?id=", "api/measures/component?component=")
          sonarqube_api_url = sonarqube_api_url + "&metricKeys=" +
            "alert_status,lines,reliability_rating,bugs,security_rating,vulnerabilities," +
            "sqale_rating,sqale_debt_ratio,sqale_index,code_smells,violations," +
            "coverage,tests,skipped_tests,complexity,duplicated_lines_density"
          @logger.info "update_sonarqube_metrics_if_possible: url to retrieve sonarqube metrics: #{sonarqube_api_url} "

          response_body = fetch_url(sonarqube_api_url)

        rescue => e
          errorMsg = "update_sonarqube_metrics_if_possible: fetch_url: #{e.message} "
          @errors << errorMsg
	  @logger.error "-----"
          @logger.error errorMsg
	  @logger.error "-----"
          @logger.error e.backtrace[0]
	  @logger.error "-----"
          @logger.error e.backtrace
	  @logger.error "-----"
        end

	jsonResult = nil
	begin
		if (nil != response_body)
			jsonResult = JSON.parse(response_body)
			# jsonResult = JSON.load(URI.open(url))
			@logger.debug jsonResult
		end
	rescue => e
		errorMsg = "update_sonarqube_metrics_if_possible: JSON.parse: #{e.message} "
		@errors << errorMsg
		@logger.error errorMsg
		@logger.error e.backtrace[0]
		@logger.error e.backtrace
	end

	begin
		if (nil != jsonResult)
			saveMetrics jsonResult
		end
	rescue => e
                errorMsg = "update_sonarqube_metrics_if_possible: saveMetrics: #{e.message} "
                @errors << errorMsg
                @logger.error errorMsg
                @logger.error e.backtrace[0]
                @logger.error e.backtrace
        end
      end

      def fetch_url(url, limit = 10)
        # You should choose a better exception.
        raise RedmineJenkins::Error::JenkinsConnectionError, 'too many HTTP redirects' if limit == 0
      
        @logger.info "Username / pwd: #{jenkins_job.jenkins_setting.sonarqube_auth_user} / #{jenkins_job.jenkins_setting.sonarqube_auth_password} "

        uri = URI(url)
      
        # authentication = ActionController::HttpAuthentication::Basic.encode_credentials(jenkins_job.jenkins_auth_user, jenkins_job.jenkins_auth_password)
        # user_pwd_str = '#{jenkins_job.jenkins_setting.auth_user}:#{jenkins_job.jenkins_setting.auth_password}'
        user_pwd_str = jenkins_job.jenkins_setting.sonarqube_auth_user + ':' + jenkins_job.jenkins_setting.sonarqube_auth_password

        @logger.info 'user_pwd_str'
        @logger.info user_pwd_str

        authorization_header = 'Basic ' + Base64.strict_encode64(user_pwd_str)
        @logger.info 'authorization_header'
        @logger.info authorization_header

        response = ''
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', 
                                    :verify_mode => OpenSSL::SSL::VERIFY_NONE) {|http|

          # http = Net::HTTP.new(uri.host, uri.port)
          @logger.info 'http'
          @logger.info http
          
          # request = Net::HTTP::Get.new(uri.path)
          request = Net::HTTP::Get.new(url)
          # request.basic_auth '#{jenkins_job.jenkins_auth_user}', '#{jenkins_job.jenkins_auth_password}'
          request['Authorization'] = authorization_header
          
          @logger.info "request: #{request}"
          @logger.info "request[Authorization]: #{request['Authorization']}"

          response = http.request request # Net::HTTPResponse object
        
          @logger.info "response: #{response} "
        }
        @logger.info "response: #{response} "

        case response
        when Net::HTTPSuccess then
          return response.body
        when Net::HTTPRedirection then
          location = response['location']
          errorMsg = "Server response: redirection from #{url} to #{location}. "
          @logger.warn errorMsg
          @errors << errorMsg
          return fetch_url(location, limit - 1)
        else
	  @logger.warn "response: #{response} "
          errorMsg = "Server returned error when querying url: #{url} (#{uri.path}). #{response}"
          @logger.warn errorMsg
          @errors << errorMsg
          return nil
        end
      end

      def saveMetrics(jsonResult)
        if (nil == jsonResult['component'])
          @errors << "No component section, in json retrieved: #{jsonResult} "
        end
        if (nil == jsonResult['component']['measures'])
          @errors << "No measures section in component section, in json retrieved: #{jsonResult} "
        end

        no_metric_read=true
        jsonResult['component']['measures'].each do |measure|
          metricName = measure["metric"]
          metricValue = measure["value"]
          if (! update_jenkins_job_metric(metricName, metricValue))
            @errors << "Retrieved metric has no valid name. Value not saved. Measure json: #{measure}"
          else
            no_metric_read=false
          end
        end

        if (! no_metric_read)
          jenkins_job.sources_report_last_update = Time.new
          # jenkins_job.sonarqube_dashboard_url = sonarqube_dashboard_url
          jenkins_job.save!
          jenkins_job.reload
        end

      end

      def update_jenkins_job_metric(metricName, metricValue)
        if (nil == metricName)
          return false
        end

        # bugs,vulnerabilities,code_smells,sqale_index,coverage,duplicated_lines_density,violations,alert_status,lines,tests,skipped_tests,complexity

        case metricName
        when 'alert_status' # Quality Gate
          jenkins_job.sources_alert_status = metricValue
        when 'lines' # Size
          jenkins_job.sources_lines = metricValue
        when 'reliability_rating' # Reliability
          jenkins_job.sources_reliability_rating = metricValue
        when 'bugs'
          jenkins_job.sources_bugs = metricValue
        when 'security_rating' # Security
          jenkins_job.sources_security_rating = metricValue
        when 'vulnerabilities'
          jenkins_job.sources_vulnerabilities = metricValue
        when 'sqale_rating' # Maintainability
          jenkins_job.sources_sqale_rating = metricValue
        when 'sqale_debt_ratio'
          jenkins_job.sources_sqale_debt_ratio = metricValue
        when 'sqale_index'
          jenkins_job.sources_sqale_index = metricValue
        when 'code_smells'
          jenkins_job.sources_code_smells = metricValue
        when 'violations' # Issues
          jenkins_job.sources_violations = metricValue
        when 'coverage' # Coverage
          jenkins_job.sources_coverage = metricValue
        when 'tests'
          jenkins_job.sources_tests = metricValue
        when 'skipped_tests'
          jenkins_job.sources_skipped_tests = metricValue
        when 'complexity' # Complexity
          jenkins_job.sources_complexity = metricValue
        when 'duplicated_lines_density'
          jenkins_job.sources_duplicated_lines_density = metricValue
        else
          @errors << "Metric has an invalid name: ${metricName}."
          return false
        end

        return true
      end

      def clean_up_builds
        jenkins_job.builds.first(number_of_builds_to_delete).map(&:destroy) if too_much_builds?
      end


      def too_much_builds?
	if jenkins_job.builds.nil?
		return false
	end
        jenkins_job.builds.size > jenkins_job.builds_to_keep
      end


      def number_of_builds_to_delete
        jenkins_job.builds.size - jenkins_job.builds_to_keep
      end


      def create_changeset(build, changesets)
        changesets.each do |changeset|
          build_changeset = jenkins_job.repository.changesets.find_by_revision(changeset['commitId'])
          next if build_changeset.nil?
          build.changesets << build_changeset unless build.changesets.include?(build_changeset)
        end
      end


      def get_jenkins_job_details
        begin
          data = jenkins_client.job.list_details(jenkins_job.name2url)
	  @logger.info "get_jenkins_job_details: data: '#{data}'"
        rescue => e
          @errors << e.message
        else
          @job_data = data
        end
      end


      def get_jenkins_build_details(build_number)
        begin
          data = jenkins_client.job.get_build_details(jenkins_job.name2url, build_number)
	  @logger.info "get_jenkins_build_details: data: '#{data}'"
	  return data
        rescue => e
          @errors << e.message
          return nil
        end
      end


      def color_to_state(color)
	      color = color.downcase
	      if color.include?('anime')
		      color = color.gsub! '_anime' ''
	      end

        case color
        when 'blue'
          'success'
        when 'red'
          'failure'
        when 'notbuilt'
          'notbuilt'
	when 'nobuilt'
	  'notbuilt'
        when 'blue_anime'
          'running'
        when 'red_anime'
          'running'
        when 'yellow'
          'unstable'
        else
          "no color->state for #{color} "
        end
      end

  end
end

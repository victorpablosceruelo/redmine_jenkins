require 'logger'
require 'net/http'
require 'json'

module JenkinsJobs
  class Base

    include Redmine::I18n

    attr_reader :jenkins_job
    attr_reader :job_data
    attr_reader :errors
    attr_reader :use_case


    def initialize(jenkins_job)
      @jenkins_job = jenkins_job
      @job_data    = nil
      @errors      = []
      @use_case    = self.class.name.split('::').last.underscore

      @log_location = STDOUT unless @log_location
      @log_level = Logger::INFO unless @log_level
      @logger = Logger.new(@log_location)
      @logger.level = @log_level

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

        clean_up_builds
      end


      def create_build(build_number)
        ## Get BuildDetails from Jenkins
        build_details = get_jenkins_build_details(build_number)

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

        update_sonarqube_metrics_if_possible()

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
          errorMsg = "Could not create changeSet: changeSet not available in Jenkins response. Jenkins Response: \n"
          @logger.warn errorMsg
          # @errors << errorMsg
          @logger.warn build_details
        else
          changeSet = build_details['changeSet']
          if (changeSet['items'] == nil)
            errorMsg = "Could not create changeSet: changeSetItems not available in Jenkins response. Jenkins Response: \n"
            @logger.warn errorMsg
            # @errors << errorMsg
            @logger.warn build_details
          else
            changeSetItems = changeSet['items']
            create_changeset(build, changeSetItems)
          end
        end
      end


      def getSonarqubeDashboardUrl(build_details)
        begin
          @logger.info "build_details:"
          @logger.info build_details
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
          errorMsg = "getSonarqubeDashboardUrl: " + e.message
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
          errorMsg = "getSonarqubeDashboardUrlAux: " + e.message
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

        begin
          sonarqube_api_url = jenkins_job.sonarqube_dashboard_url
          sonarqube_api_url = sonarqube_api_url.gsub("dashboard?id=", "api/measures/component?component=")
          sonarqube_api_url = sonarqube_api_url + "&metricKeys=bugs,vulnerabilities"
          @logger.info "update_sonarqube_metrics_if_possible: url to retrieve sonarqube metrics: " + sonarqube_api_url

          response = fetch_url(sonarqube_api_url)
          jsonResult = JSON.parse(response)
          # jsonResult = JSON.load(URI.open(url))
          @logger.info jsonResult



        rescue => e
          errorMsg = "update_sonarqube_metrics_if_possible: " + e.message
          @errors << errorMsg
          @logger.error errorMsg
          @logger.error e.backtrace[0]
          @logger.error e.backtrace
        end
      end

      def fetch_url(url, limit = 10)
        # You should choose a better exception.
        raise RedmineJenkins::Error::JenkinsConnectionError, 'too many HTTP redirects' if limit == 0
      
        @logger.info "Username / pwd: #{jenkins_job.jenkins_setting.auth_user} / #{jenkins_job.jenkins_setting.auth_password} "

        uri = URI(url)
        response = Net::HTTP.get_response(uri)
        @logger.info response
      
        case response
        when Net::HTTPSuccess then
          response
        when Net::HTTPRedirection then
          location = response['location']
          errorMsg = "Server response: redirection from #{url} to #{location}. "
          @logger.warn errorMsg
          @errors << errorMsg
          fetch_url(location, limit - 1)
        else
          errorMsg = "Server returned error value #{response.value}. Url: #{url} "
          @logger.warn errorMsg
          @errors << errorMsg
          response.value
        end
      end


      def clean_up_builds
        jenkins_job.builds.first(number_of_builds_to_delete).map(&:destroy) if too_much_builds?
      end


      def too_much_builds?
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
        rescue => e
          @errors << e.message
        else
          @job_data = data
        end
      end


      def get_jenkins_build_details(build_number)
        begin
          data = jenkins_client.job.get_build_details(jenkins_job.name2url, build_number)
        rescue => e
          @errors << e.message
          nil
        else
          data
        end
      end


      def color_to_state(color)
        case color
        when 'blue'
          'success'
        when 'red'
          'failure'
        when 'notbuilt'
          'notbuilt'
        when 'blue_anime'
          'running'
        when 'red_anime'
          'running'
        when 'yellow'
          'unstable'
        else
          'no color->state for ' + color
        end
      end

  end
end

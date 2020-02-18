require 'logger'

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
        jenkins_job.description           = job_data['description'] || ''
        jenkins_job.health_report         = job_data['healthReport']
        jenkins_job.latest_build_number   = !job_data['lastBuild'].nil? ? job_data['lastBuild']['number'] : 0
        jenkins_job.latest_build_date     = jenkins_job.builds.last.finished_at rescue ''
        jenkins_job.latest_build_duration = jenkins_job.builds.last.duration rescue ''
        jenkins_job.sonarqubeDashboardUrl = getSonarqubeDashboardUrl()
        jenkins_job.save!
        jenkins_job.reload
        true
      end

      def getSonarqubeDashboardUrl()
        begin
          job_data.each do |job_subdata|
            if ! (job_subdata.nil?) 
              if ! (job_subdata['_class'].nil?)
                if (job_subdata['_class'] == 'hudson.plugins.sonar.action.SonarAnalysisAction')
                  sonarqubeDashboardUrl = job_subdata['sonarqubeDashboardUrl']
                  @logger.info "sonarqubeDashboardUrl: '#{sonarqubeDashboardUrl}'"
                  return sonarqubeDashboardUrl
                end
              end
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
      end


      def update_build(build, build_number)
        @logger.info "update_build: Updating build information for build number '#{build_number}'"

        ## Get BuildDetails from Jenkins
        build_details = get_jenkins_build_details(build_number)

        @logger.info "update_build: build_details: '#{build_details}'"

        ## Update the AR object with new data
        build.result      = build_details['result'].nil? ? 'running' : build_details['result']
        build.building    = build_details['building']
        build.duration    = build_details['duration']
        build.finished_at = Time.at(build_details['timestamp'].to_f / 1000)
        build.save!

        ## Update changesets. 
        create_changeset_if_possible(build, build_details)
      end

      def create_changeset_if_possible(build, build_details)
        ## Update changesets. Be careful: sometimes the answer does not have them ... 
        if (build_details['changeSet'] == nil)
          errorMsg = "Could not create changeSet: changeSet not available in Jenkins response."
          @logger.warn errorMsg
          @errors << errorMsg
        else
          changeSet = build_details['changeSet']
          if (changeSet['items'] == nil)
            errorMsg = "Could not create changeSet: changeSetItems not available in Jenkins response."
            @logger.warn errorMsg
            @errors << errorMsg
          else
            changeSetItems = changeSet['items']
            create_changeset(build, changeSetItems)
          end
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
        else
          ''
        end
      end

  end
end

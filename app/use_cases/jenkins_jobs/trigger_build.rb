module JenkinsJobs
  class TriggerBuild < Base

    def execute
      build_number = ''
      opts = {}
      opts['build_start_timeout'] = 30 if jenkins_job.wait_for_build_id

      begin
        build_number = jenkins_client.job.build(jenkins_job.name2url, {}, opts)
      rescue => e
        @errors << e.message
        @logger.error e.message
        @logger.error e.backtrace.join("\n")
      else
        jenkins_job.latest_build_number = build_number if jenkins_job.wait_for_build_id
        jenkins_job.state = 'running'
        @logger.error 'Jenkins job state is running'
        jenkins_job.save!
        @logger.error 'Jenkins job saved! '
      end
    end

  end
end

module JenkinsJobs
  class UpdateAllBuilds < Base

    def execute
      return if !job_status_updated?
      
      begin
      	do_create_builds(job_data['builds'].take(jenkins_job.builds_to_keep))
      rescue => e
	errorMsg = "UpdateAllBuilds: " + e.message
        @errors << errorMsg
        @logger.error errorMsg
        @logger.error e.backtrace.join("\n")
	raise e
      end

    end

  end
end

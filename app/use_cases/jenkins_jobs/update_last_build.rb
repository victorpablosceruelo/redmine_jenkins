module JenkinsJobs
  class UpdateLastBuild < Base

    def execute
      return if !job_status_updated?

      begin
        last_build = job_data['builds'].any? ? [job_data['builds'].first] : []
        do_create_builds(last_build, true)
      rescue => e
        @errors << e.message
        @logger.error e.message
        @logger.error e.backtrace.join("\n")
      end

    end

  end
end

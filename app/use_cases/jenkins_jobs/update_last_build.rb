module JenkinsJobs
  class UpdateLastBuild < Base

    def execute
      begin
        do_create_builds()
      rescue => e
        errorMsg = "UpdateLastBuild: " + e.message
        @errors << errorMsg
        @logger.error errorMsg
        @logger.error e.backtrace.join("\n")
      end

    end

  end
end

module JenkinsJobs
  class CreateBuilds < Base

    def execute
      begin
      	do_create_builds()
      rescue => e
	errorMsg = "CreateBuilds: " + e.message
        @errors << errorMsg
        @logger.error errorMsg
        @logger.error e.backtrace.join("\n")
	raise e
      end

    end

  end
end

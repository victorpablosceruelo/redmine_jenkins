module BuildManager
  class << self

    def create_builds!(job, logger)
      JenkinsJobs::CreateBuilds.new(job, logger).call
    end


    def update_all_builds!(job, logger)
      JenkinsJobs::UpdateAllBuilds.new(job, logger).call
    end


    def update_last_build!(job, logger)
      JenkinsJobs::UpdateLastBuild.new(job, logger).call
    end


    def trigger_build!(job, logger)
      JenkinsJobs::TriggerBuild.new(job, logger).call
    end

  end
end

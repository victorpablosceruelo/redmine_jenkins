class UpdateJenkinsJobs < ActiveRecord::Migration[5.0]

  def up
    add_column :jenkins_jobs, :sonarqubeDashboardUrl, :string, default: ''
  end

  def down
    remove_column :jenkins_jobs, :sonarqubeDashboardUrl
  end
end

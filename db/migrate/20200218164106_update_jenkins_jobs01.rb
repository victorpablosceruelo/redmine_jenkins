class UpdateJenkinsJobs01 < ActiveRecord::Migration[5.0]

  def up
    add_column :jenkins_jobs, :sonarqube_dashboard_url, :string, default: ''
    add_column :jenkins_jobs, :state_color, :string, default: ''
  end

  def down
    remove_column :jenkins_jobs, :state_color
    remove_column :jenkins_jobs, :sonarqube_dashboard_url
  end
end

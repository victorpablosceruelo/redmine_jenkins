class UpdateJenkinsJobs03 < ActiveRecord::Migration[5.0]

  def up
	  change_column :jenkins_jobs, :builds_to_keep, :integer, default: 3
  end

  def down
	  change_column :jenkins_jobs, :builds_to_keep, :integer, default: 10 
  end

end

class UpdateJenkinsSettings01 < ActiveRecord::Migration[5.0]

  def up

	  remove_column :jenkins_settings, :auth_user
	  remove_column :jenkins_settings, :auth_password
	  remove_column :jenkins_settings, :url
	  remove_column :jenkins_settings, :show_compact
	  remove_column :jenkins_settings, :wait_for_build_id

  end

  def down

	add_column :jenkins_settings, :auth_user, :string, null: false, default: ''
	add_column :jenkins_settings, :auth_password, :string, null: false, default: ''
	add_column :jenkins_settings, :url, :string
	add_column :jenkins_settings, :show_compact, :boolean, default: false
	add_column :jenkins_settings, :wait_for_build_id, :boolean, default: false

  end

end

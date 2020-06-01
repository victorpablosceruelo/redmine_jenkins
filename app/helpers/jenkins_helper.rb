module JenkinsHelper

  def state_to_css_class(state)
    case state.downcase
    when 'success'
      'success'
    when 'failure', 'aborted'
      'important'
    when 'unstable', 'invalid'
      'warning'
    when 'running'
      'info'
    when 'not_run'
      ''
    else
      ''
    end
  end

  def jenkins_job_state_to_label(state)
	if !state.nil?
		return state.gsub('_', ' ').capitalize
	end
	''
  end

  def state_color_to_image(state_color, description)
	if state_color.blank?
		return ''
	end

	state_color = state_color.downcase

	if state_color.include?('notbuilt')
		state_color = state_color.gsub("notbuilt", "nobuilt") 
	end

	image_fileextension = ".png"
	if state_color.include?('anime')
		image_fileextension = ".gif"
	end

	image_file = state_color + image_fileextension
	image_file = image_file.gsub(" ", "_")

	image_tag(plugin_asset_link('redmine_jenkins', image_file), 
        		alt: description, class: 'state_color_image',
			title: description, longdesc: description,
			data: { title: description })

  end

  def jenkins_logs_icon()
    description = l(:label_see_jenkins_job_build_logs)
    image_tag(plugin_asset_link('redmine_jenkins', 'logs-icon.png'), 
              alt: description, class: 'jenkins_jobs_logs_icon',
              title: description, longdesc: description,
              data: { title: description })
    # alt: icon,
  end

  def weather_icon(icon, description)
    image_tag(plugin_asset_link('redmine_jenkins', icon), 
              alt: description, class: 'weather_image_icon',
              title: description, longdesc: description,
              data: { title: description })
    # alt: icon,
  end

  def plugin_asset_link(plugin_name, asset_name)
    File.join(Redmine::Utils.relative_url_root, 'plugin_assets', plugin_name, 'images', asset_name)
  end


  def link_to_jenkins_job_latest_build(job)
    # longdesc = l(:label_see_jenkins_job_build) + " ##{job.latest_build_number}"
    # url    = job.latest_build_number == 0 ? 'javascript:void(0);' : job.latest_build_url
    # target = job.latest_build_number == 0 ? '' : '_blank'
    # link_to "##{job.latest_build_number}", url, target: target, longdesc: longdesc, alt: longdesc, title: longdesc
    return "##{job.latest_build_number}"
  end


  def link_to_sonarqube_dashboard_url(sonarqube_dashboard_url)
    longdesc = l(:label_see_sonarqube_dashboard_url)
    link_to l(:label_sonarqube_dashboard_url), sonarqube_dashboard_url, target: '_blank', longdesc: longdesc, alt: longdesc, title: longdesc
  end


  def render_repo_name(job)
    if job.repository.nil?
      content_tag(:em, 'deleted')
    else
      (job.repository.identifier.nil? || job.repository.identifier.empty?) ? 'default' : job.repository.identifier
    end
  end


  def render_selected_repo(job)
    if job.repository.nil? || job.repository.identifier.blank?
      [ 'default' ]
    else
      [ job.repository.identifier, job.repository.id ]
    end
  end

end

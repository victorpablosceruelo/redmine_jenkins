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

  def state_to_label(state)
    state.gsub('_', ' ').capitalize
  end

  def state_color_to_image(state_color, description)
    image_tag(plugin_asset_link('redmine_jenkins', state_color), 
              alt: description, style: 'display: inline-block; vertical-align: bottom;',
              title: description, longdesc: description,
              data: { title: description })
  end

  def weather_icon(icon, description)
    image_tag(plugin_asset_link('redmine_jenkins', icon), 
              alt: description, style: 'display: inline-block; vertical-align: bottom;',
              title: description, longdesc: description,
              data: { title: description })
    # alt: icon,
  end

  def plugin_asset_link(plugin_name, asset_name)
    File.join(Redmine::Utils.relative_url_root, 'plugin_assets', plugin_name, 'images', asset_name)
  end


  def link_to_jenkins_job(job)
    url    = job.latest_build_number == 0 ? 'javascript:void(0);' : job.latest_build_url
    target = job.latest_build_number == 0 ? '' : 'about_blank'
    link_to "##{job.latest_build_number}", url, target: target
  end


  def link_to_sonarqube_dashboard_url(sonarqube_dashboard_url)
    link_to l(:label_sonarqube_dashboard_url), sonarqube_dashboard_url, target: '_blank'
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

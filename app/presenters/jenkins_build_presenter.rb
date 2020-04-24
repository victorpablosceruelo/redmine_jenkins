class JenkinsBuildPresenter < SimpleDelegator

  attr_reader :jenkins_job_build

  def initialize(jenkins_job_build, template)
    super(template)
    @jenkins_job_build = jenkins_job_build
  end


  def number
    "##{jenkins_job_build.number}"
  end

  def finished_at
    convert_date_to_str(jenkins_job_build.finished_at)
  end

  def duration
        s = ''
        if !jenkins_job_build.duration.nil?
                s << l(:label_job_duration)
                s << ': '
                s << Time.at(jenkins_job_build.duration/1000).strftime("%M:%S") rescue "00:00"
        end
        s.html_safe
  end

  def building_result
	# img_desc = get_job_latest_build_image_description(jenkins_job)

	s = ''
	# s << content_tag(:span, state_color_to_image(jenkins_job.state_color, img_desc), class: 'job_status_line')
	# s << content_tag(:span, link_to_jenkins_job_latest_build_console(jenkins_job).html_safe, class: 'job_status_line')
	# s << content_tag(:span, link_to_latest_build_console_output.html_safe, class: 'job_status_line')
	
	console_url = console_jenkins_job_path(jenkins_job_build.jenkins_job.project, jenkins_job_build.jenkins_job, jenkins_job_build)
        console_window_title = "Console of build ##{build.number}"
	console_link_title = jenkins_logs_icon
	# console_link_title = 'View console'
        s << content_tag(:span, link_to(console_link_title, console_url, title: console_window_title, class: 'modal-box-close-only'))

	s << content_tag(:span, '', class: 'icon icon-running') if jenkins_job_build.building?
	s.html_safe
  end

  private

  def alert_status_to_str(alert_status)
    if ((alert_status == nil) || (alert_status == ''))
      return l(:label_sources_report_cell_no_data)
    end

    return alert_status
  end

  def convert_date_to_str(date_value)
	# "#{format_time(jenkins_job.latest_build_date)}"
	if (date_value == nil)
		return "never"
	end
	date_value.strftime('%Y/%m/%d %H:%M')
  end

  def get_int_value(value_in)
    if ((value_in == nil) || (value_in == ''))
      return '0'
    else
      if (value_in.is_a? String)
        if (value_in.strip == '')
          return '0'
        end
      else
        return value_in.to_s
      end
    end
  end

  def minutes_to_hours(value_in)
    if ((value_in == nil) || (value_in == ''))
      return '0'
    else
      if (value_in.is_a? String)
        if (value_in.strip == '')
          return '0'
        end
      else
        return (value_in / 60).to_s
      end
    end
  end


    
  
  
  def render_jenkins_job_latest_build_link_and_state(jenkins_job)
      img_desc = get_job_latest_build_image_description(jenkins_job)

      s = ''
      s << content_tag(:span, link_to_jenkins_job_latest_build(jenkins_job).html_safe, class: 'label label-info')
      s << content_tag(:span, state_color_to_image(jenkins_job.state_color, img_desc), class: 'job_status_line')
      # s << content_tag(:span, link_to_jenkins_job_latest_build_console(jenkins_job).html_safe, class: 'job_status_line')
      s << content_tag(:span, link_to_latest_build_console_output.html_safe, class: 'job_status_line')

      s.html_safe
    end

    def get_job_latest_build_image_description(jenkins_job)
	s = ''
	if (! jenkins_job.state.blank?)
		s << l(:label_job_build_state)
		s << ": "
		s << jenkins_job_state_to_label(jenkins_job.state)
		if (! jenkins_job.state_color.nil?) and (! jenkins_job.state_color.empty?)
       			s << " (" 
			s << jenkins_job.state_color
	 		s << ")"
		end
	end
	s.html_safe
    end 

    def getLiStyleForIcons
      "line-height:34px; margin:2px; vertical-align:middle; "
    end

    def link_to_jenkins_job_latest_build_console
        if ! jenkins_job.latest_build_number.nil?
                url    = jenkins_job.latest_build_number == 0 ? 'javascript:void(0);' : jenkins_job.latest_build_url + '/console'
                target = jenkins_job.latest_build_number == 0 ? '' : '_blank'
                return link_to jenkins_logs_icon, url, target: target
                # Attributes included in image: longdesc: longdesc, alt: longdesc, title: longdesc
        end
        ''
    end

    def link_to_latest_build_console_output
	link_title = l(:label_see_console_output)
	if ! jenkins_job.latest_build_number.nil?
		if jenkins_job.latest_build_number == 0
			url = 'javascript:void(0);'
			return link_to(link_title, url, title: link_title, class: 'modal-box-close-only')
		else
			url = console_jenkins_job_path(jenkins_job.project, jenkins_job)
			return link_to(link_title, url, title: link_title, class: 'modal-box-close-only')

			# return link_to(link_title, url, title: link_title, class: 'modal-box-close-only')
		end
	end 

	# title: l(:label_see_console_output), remote: true, target:'_blank'
	return ''
    end


    def render_job_builds_infos_table_row(build)
	s = ''
	url = console_jenkins_job_path(jenkins_job.project, jenkins_job, build)
	link_title = "##{build.number}"
	s << content_tag(:td, link_to(link_title, url, title: link_title, class: 'modal-box-close-only'))
	
	s.html_safe
    end

end

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

  def result
	  jenkins_job_build.result
  end

  def duration
        s = ''
        if !jenkins_job_build.duration.nil?
                # s << l(:label_job_duration)
                # s << ': '
                s << Time.at(jenkins_job_build.duration/1000).strftime("%M\' %S\"") rescue "00:00"
        end
        s.html_safe
  end

  def building_result
	# img_desc = get_job_latest_build_image_description(jenkins_job)

	s = ''
	# if (jenkins_job_build.number == jenkins_job_build.jenkins_job.latest_build_number)
	#	img_desc = get_build_image_description(jenkins_job_build.jenkins_job.state, jenkins_job_build.jenkins_job.state_color)
	#	s << content_tag(:span, state_color_to_image(jenkins_job_build.jenkins_job.state_color, img_desc), class: 'job_status_line')
	# end

	s << jenkins_job_state_to_label(jenkins_job_build.result)
	
	console_url = console_jenkins_job_path(jenkins_job_build.jenkins_job.project, jenkins_job_build.jenkins_job, jenkins_job_build)
        console_window_title = "Console of build ##{jenkins_job_build.number}"
	console_link_title = jenkins_logs_icon
	# console_link_title = 'View console'
        s << content_tag(:span, link_to(console_link_title, console_url, title: console_window_title, class: 'modal-box-jenkins-build-logs  modal-box-close-only'))

	s << content_tag(:span, '', class: 'icon icon-running') if jenkins_job_build.building?
	s.html_safe
  end

  def view_build_logs
	s = ''
	console_url = console_jenkins_job_path(jenkins_job_build.jenkins_job.project, jenkins_job_build.jenkins_job, jenkins_job_build)
        console_window_title = l(:label_jenkins_job_build_logs_of) + " ##{jenkins_job_build.number}"
        # console_link_title = jenkins_logs_icon
	s << content_tag(:span, link_to(console_window_title, console_url, title: console_window_title, class: 'modal-box-jenkins-build-logs modal-box-close-only'))
	s.html_safe
  end

  private

    def get_build_image_description(state, state_color)
        s = ''
        if (! state.blank?)
                s << l(:label_job_build_state)
                s << ": "
                s << jenkins_job_state_to_label(state)
                if (! state_color.nil?) and (! state_color.empty?)
                        s << " ("
                        s << state_color
                        s << ")"
                end
        end
        s.html_safe
    end

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

end

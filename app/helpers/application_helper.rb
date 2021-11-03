module ApplicationHelper
  def b(value)
    value ? t(:true) : t(:false)
  end

  def score_level_and_name_new(level)
    case level
    when 1 then "Nível #{level}</br>(Emergente)"
    when 2 then "Nível #{level}</br>(Básico)"
    when 3 then "Nível #{level}</br>(Intermediário)"
    when 4 then "Nível #{level}</br>(Avançado)"
    else ''
    end
  end

  def score_level_and_name(level)
    case level
    when 1 then "Nível #{level} (Exploratório)"
    when 2 then "Nível #{level} (Básico)"
    when 3 then "Nível #{level} (Intermediário)"
    when 4 then "Nível #{level} (Avançado)"
    when 5 then "Nível #{level} (Muito Avançado)"
    else ''
    end
  end

  def profile_options
    User::PROFILE.map do |option|
      [human_profile_name(option), option]
    end
  end

  def human_profile_name(profile)
    t(profile, scope: 'profiles')
  end

  def activity_options
    activity = ["school", "teacher"]
    activity.map do |option|
      [human_activity_name(option), option]
    end
  end

  def human_activity_name(activity)
    t(activity, scope: 'activities')
  end

end

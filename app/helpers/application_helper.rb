module ApplicationHelper
  def psychologist_calendar_week_path(profile, week, home_page:)
    anchor = "psychologist-#{profile.id}-calendar"

    if home_page
      root_path(
        week: week,
        calendar: profile.id,
        anchor: anchor
      )
    else
      psychologist_path(
        profile,
        week: week,
        calendar: profile.id,
        anchor: anchor
      )
    end
  end
end

class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    # Разрешаем передачу дополнительных полей при регистрации
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :phone, :is_client, :is_psychologist])
    # Разрешаем передачу полей при редактировании профиля
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :phone, :is_client, :is_psychologist])
  end
end
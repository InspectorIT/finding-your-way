class Auth::RegistrationsController < ApplicationController
  # Метод для отображения формы регистрации
  def new
    @user = User.new
  end

  # Метод для сохранения пользователя в базу
  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id # Сразу логиним пользователя
      # Перенаправляем на главную с сообщением об успехе
      redirect_to root_path, notice: "Регистрация прошла успешно!"
    else
      # Если есть ошибки (например, занят email), снова показываем форму.
      # status: :unprocessable_entity важен для корректной работы Turbo в современных Rails
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    # has_secure_password ожидает поля :password и :password_confirmation
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :phone, :role)
  end
end

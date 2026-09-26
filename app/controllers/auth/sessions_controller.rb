class Auth::SessionsController < ApplicationController
  # Показывает форму входа
  def new
  end

  # Обрабатывает отправку формы входа
  def create
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Вы успешно вошли в систему!"
    else
      # flash.now показывает сообщение только на текущей странице (чтобы оно не осталось после редиректа)
      flash.now[:alert] = "Неверный email или пароль"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Вы вышли из системы"
  end
end
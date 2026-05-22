Rails.application.routes.draw do
  # Healthcheck Rails — оставим, не мешает.
  get "up" => "rails/health#show", as: :rails_health_check

  # POST /students                              → создание студента
  # DELETE /students/:user_id                   → удаление студента (требует Bearer)
  post   "/students",         to: "students#create"
  delete "/students/:user_id", to: "students#destroy"

  # GET /schools/:school_id/classes             → список классов школы
  # GET /schools/:school_id/classes/:class_id/students → список студентов класса
  get "/schools/:school_id/classes",                              to: "classes#index"
  get "/schools/:school_id/classes/:class_id/students",           to: "class_students#index"
end

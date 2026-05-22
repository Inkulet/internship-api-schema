class StudentsController < ApplicationController
  include Authenticatable

  before_action :authenticate_student!, only: :destroy

  # POST /students
  def create
    student = Student.create!(student_params)
    response.set_header("X-Auth-Token", student.reload.auth_token)
    render json: student.to_api_hash, status: :created
  end

  # DELETE /students/:user_id
  def destroy
    @current_student.destroy
    head :no_content
  end

  private

  def student_params
    params.permit(:first_name, :last_name, :surname, :class_id, :school_id)
  end
end

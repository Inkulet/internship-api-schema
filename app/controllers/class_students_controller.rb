class ClassStudentsController < ApplicationController
  include Paginatable

  # GET /schools/:school_id/classes/:class_id/students
  def index
    students = Student
                 .where(school_id: params[:school_id], class_id: params[:class_id])
                 .order(:last_name, :first_name)

    render json: { data: paginate(students).map(&:to_api_hash) }
  end
end

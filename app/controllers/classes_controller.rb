class ClassesController < ApplicationController
  include Paginatable

  # GET /schools/:school_id/classes
  def index
    classes = SchoolClass
                .where(school_id: params[:school_id])
                .order(:number, :letter)

    render json: { data: paginate(classes).map(&:to_api_hash) }
  end
end

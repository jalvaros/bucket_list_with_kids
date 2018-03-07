class DestinationsController < ApplicationController
  include AlgoliaSearch

  before_action :set_destination, only: [:show, :edit, :update, :destroy]
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :authenticate_admin!, only: [:new, :edit, :update, :destroy]


  algoliasearch per_environment: true, disable_indexing: Rails.env.test? do
  end

  algoliasearch do
    # list of attribute used to build an Algolia record
    attributes :name, :entity, :description, :street, :locality, :region,
    :holiday_type, :theme, :bucket_list_count, :average_review_score

    # the `searchableAttributes` (formerly known as attributesToIndex) setting defines the attributes
    # you want to search in: here `title`, `subtitle` & `description`.
    # You need to list them by order of importance. `description` is tagged as
    # `unordered` to avoid taking the position of a match into account in that attribute.
    searchableAttributes ['name', 'entity', 'unordered(description)']

     # the `customRanking` setting defines the ranking criteria use to compare two matching
    # records in case their text-relevance is equal. It should reflect your record popularity.
    customRanking ['desc(bucket_list_count)']
  end

  def index
    policy_scope(Destination)
    if params[:query].present?
      @experiences = Experience.search_by_name_description(params[:query])
    else
    @destinations = Destination.all
    #future code to mix destination, accomdation and experiences
    end

# CODE TO ADD MAP TO HOME INDEX PAGE WITH MARKERS FOR ALL 3 ENTITIES
    @destinations = Destination.where.not(latitude: nil, longitude: nil)
    @accommodations = Accommodation.where.not(latitude: nil, longitude: nil)
    @experiences = Experience.where.not(latitude: nil, longitude: nil)
    @all_entities = @destinations + @experiences + @accommodations

    @markers = @all_entities.map do |e|
      {
        lat: e.latitude,
        lng: e.longitude,
        # infoWindow: { content: entity.name }
        infoWindow: { content: render_to_string(partial: "shared/marker_window", locals: { selection: e }) }
      }
    end
  end

  # TESTING A UPVOTE ACTION
  def upvote
    @destination = Destination.find(params[:id])
    authorize @destination
    @destination.upvote_by(current_user)
    redirect_to destinations_path
    # redirect_to destination_path(@destination)
  end

  # def downvote
  #   @destination.upvote_by(current_user)
  #   redirect_to destination_path(@destination)
  # end

  def mix
    #future code
  end

  def show
    authorize @destination
    @markers = [{ lat: @destination.latitude, lng: @destination.longitude }]
  end

  def new
    @destination = Destination.new
    authorize @destination
  end

  def create
    @destination = Destination.new(params_destination)
    authorize @destination
    @destination.user = current_user
    @destination.save
    redirect_to destination_path(@destination)
  end

  def edit
    authorize @destination
  end

  def update
    authorize @destination
    if @destination.update(params_destination)
    redirect_to destination_path(@destination)
    else
    render :new
  end
 end

 def destroy
    authorize @destination
    @destination.destroy
    redirect_to experiences_path
  end

private

  def set_destination
    @destination = Destination.find(params[:id])
  end

  def params_destination
    params.require(:destination).permit(:name, :description, :street_number, :street, :locality, :country, :region, :latitude, :longitude, :photo, :entity, :holiday_type, :theme, :kids_age_from, :kids_age_to, :duration, :price, :bucket_list_count, :average_review_score)
  end
end



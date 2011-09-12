class QueryController < ApplicationController

  before_filter :authenticate_user!

  SCRIPT = {"pivot_table" => 'pivot_table.R.erb',
            "line_graph"  => 'line_graph.R.erb',
            "area_graph"  => 'area_graph.R.erb'}

  def index
    params[:query] = Hash.new unless params[:query]
    if params[:do]=="load_stored_query"
      stored_query = StoredQuery.find(params[:stored_query_id])
      params[:query][:result_set_ids] =  params[:result_set_ids]
      [:name,:aggregate,:variable,:rows,:columns,:filters,:display].each do |field|
        params[:query][field] = stored_query[field]
      end
      @query_has_results =perform_query(params[:query])
    end
    user_session[:query] = params[:query]
  end

  def result_plot
    send_file(user_session[:query]["result_file"], :disposition => 'inline', :type => 'image/png',:filename=>"plot.png")
  end

  private

  def perform_query(query)
    #clean
    File.delete(result_file) if File.exists?(result_file)

    query[:result_file] = result_file
    query[:input_files] = ResultSet.where(:id=>query[:result_set_ids]).collect{|r|r.file("csv")}
    @query = query

    template = File.read(File.join(Rails.root, 'lib', SCRIPT[query[:display]]))
    text = ERB.new(template).result(binding)
    puts text

    f = Tempfile.new("R")
    f2 = Tempfile.new("S")
    begin
      f.write(text)
      f.flush
      `R CMD BATCH --vanilla --quiet #{f.path} #{f2.path}`
    ensure
      f.close
      f2.close
      f.unlink
      f2.unlink
    end

    File.exists?(result_file)
  end

  def result_file
    File.join(Dir.tmpdir, "leaqweb.res")
  end

  def current_query
    @current_query ||= user_session[:query]
  end

end

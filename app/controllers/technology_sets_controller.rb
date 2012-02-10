#--
# Copyright (c) 2009-2012, Public Research Center Henri Tudor
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

class TechnologySetsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html
  respond_to :json, :only => [:show]

  def index
    @technology_sets = TechnologySet.order(:name)
  end

  def list
    @technology_sets, @total_technology_sets  = filter_list(TechnologySet,["name","description"])
    render :layout => false, :partial => "list.json"
  end

  def show
    @technology_set = TechnologySet.find(params[:id])
    respond_to do |format|
      format.html { redirect_to edit_technology_set_path(@technology_set) }
      format.js { render :json => {:technology_set=>{:id=>@technology_set.id, :technologies=>@technology_set.technologies}}.to_json }
    end
  end

  def new
    respond_with(@technology_set = TechnologySet.new)
  end

  def edit
    respond_with(@technology_set = TechnologySet.find(params[:id]))
  end

  def create
    respond_with(@technology_set = TechnologySet.create(params[:technology_set]))
  end

  def update
    @technology_set = TechnologySet.find(params[:id])
    case params[:do]
      when "update_technologies"
        @technology_set.technologies = Technology.find_by_list_name(params[:technologies])
        flash[:notice] = 'TechnologySet was successfully created.' if @technology_set.save
      when "update"
        @technology_set.update_attributes(params[:technology_set])
        respond_with(@technology_set)
        return
      when "delete_pv"
        ParameterValue.destroy(checkbox_ids)
      when "add_pv"
        att = params[:pv]
        att[:technology_subset] = TechnologySet.find(att[:technology_subset].to_i) if att[:technology_subset]
        att[:parameter] = Parameter.find_by_name(att[:parameter])
        att[:technology_set] = @technology_set
        pv = ParameterValue.new(att)
        flash[:notice] = 'Parameter value was successfully added.' if pv.save
    end if params[:do]
    redirect_to(edit_technology_set_path(@technology_set))
  end

  def destroy
    TechnologySet.destroy(params[:id])
    redirect_to(technology_sets_url)
  end

  def destroy_all
    TechnologySet.destroy(checkbox_ids)
    redirect_to(technology_sets_url)
  end

  def suggest
    text = params[:term]
    res = TechnologySet.order(:name).matching_text(text).limit(10).map(&:name)
    res << "..." if res.size==10
    render :json => res.to_json
  end

end

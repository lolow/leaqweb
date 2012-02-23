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
# NON INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

class StoredQueriesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, except: :list
  respond_to :json, only:   :list

  def index
    params[:display] = "pivot_table" unless params[:display]
  end

  def list
    @stored_queries, @total_stored_queries = filter_list(StoredQuery,%w(name))
    render layout: false, :formats => [:json], partial: "list"
  end

  def show
    redirect_to edit_stored_query_path(StoredQuery.find(params[:id]))
  end

  def new
    respond_with(@stored_query = StoredQuery.new)
  end

  def duplicate
    @stored_query = StoredQuery.find(params[:id]).duplicate_as_new
    render action: "new"
  end

  def edit
    respond_with(@stored_query = StoredQuery.find(params[:id]))
  end

  def create
    respond_with(@stored_query = StoredQuery.create(params[:stored_query]))
  end

  def update
    @stored_query = StoredQuery.find(params[:id])
    if @stored_query.update_attributes(params[:stored_query])
      redirect_to(@stored_query, notice: 'Query was successfully updated.')
    else
      render action: "edit"
    end
  end

  def upload
    if params[:import] && File.exist?(params[:import]["stored_query"].tempfile.path)
      StoredQuery.import(params[:import]["stored_query"].tempfile.path)
      redirect_to(stored_queries_url, notice: 'File has been imported.')
    else
      redirect_to(stored_queries_url, notice: 'No file to upload.')
    end
  end

  def zip
    if StoredQuery.find_all_by_id(params[:stored_queries_id]).size > 0
      f = Tempfile.new("queries")
      StoredQuery.zip(f.path,params[:stored_queries_id])
      send_file f.path, type: "application/zip",
                        filename: "stored_queries.zip"
      f.close
    else
      redirect_to(stored_queries_url, notice: 'No stored queries selected.')
    end
  end

  def destroy
    StoredQuery.find(params[:id]).destroy
    redirect_to(stored_queries_url)
  end

  def destroy_all
    StoredQuery.where(id: checkbox_ids).map(&:destroy)
    redirect_to(stored_queries_url)
  end

end
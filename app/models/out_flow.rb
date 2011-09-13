# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class OutFlow < Flow

  has_many :parameter_values, :dependent => :delete_all

end
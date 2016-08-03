# frozen_string_literal: false
# Copyright (c) 2003, 2004 Jim Weirich, 2009 Eric Hodel
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

require 'rubygems'
require 'rubygems/package'
begin
  gem 'rake'
rescue Gem::LoadError
end

require 'rake/packagetask'

##
# Create a package based upon a Gem::Specification.  Gem packages, as well as
# zip files and tar/gzipped packages can be produced by this task.
#
# In addition to the Rake targets generated by Rake::PackageTask, a
# Gem::PackageTask will also generate the following tasks:
#
# [<b>"<em>package_dir</em>/<em>name</em>-<em>version</em>.gem"</b>]
#   Create a RubyGems package with the given name and version.
#
# Example using a Gem::Specification:
#
#   require 'rubygems'
#   require 'rubygems/package_task'
#
#   spec = Gem::Specification.new do |s|
#     s.summary = "Ruby based make-like utility."
#     s.name = 'rake'
#     s.version = PKG_VERSION
#     s.requirements << 'none'
#     s.files = PKG_FILES
#     s.description = <<-EOF
#   Rake is a Make-like program implemented in Ruby. Tasks
#   and dependencies are specified in standard Ruby syntax.
#     EOF
#   end
#
#   Gem::PackageTask.new(spec) do |pkg|
#     pkg.need_zip = true
#     pkg.need_tar = true
#   end

class Gem::PackageTask < Rake::PackageTask

  ##
  # Ruby Gem::Specification containing the metadata for this package.  The
  # name, version and package_files are automatically determined from the
  # gemspec and don't need to be explicitly provided.

  attr_accessor :gem_spec

  ##
  # Create a Gem Package task library.  Automatically define the gem if a
  # block is given.  If no block is supplied, then #define needs to be called
  # to define the task.

  def initialize(gem_spec)
    init gem_spec
    yield self if block_given?
    define if block_given?
  end

  ##
  # Initialization tasks without the "yield self" or define operations.

  def init(gem)
    super gem.full_name, :noversion
    @gem_spec = gem
    @package_files += gem_spec.files if gem_spec.files
  end

  ##
  # Create the Rake tasks and actions specified by this Gem::PackageTask.
  # (+define+ is automatically called if a block is given to +new+).

  def define
    super

    gem_file = File.basename gem_spec.cache_file
    gem_path = File.join package_dir, gem_file
    gem_dir  = File.join package_dir, gem_spec.full_name

    task :package => [:gem]

    directory package_dir
    directory gem_dir

    desc "Build the gem file #{gem_file}"
    task :gem => [gem_path]

    trace = Rake.application.options.trace
    Gem.configuration.verbose = trace

    file gem_path => [package_dir, gem_dir] + @gem_spec.files do
      chdir(gem_dir) do
        when_writing "Creating #{gem_spec.file_name}" do
          Gem::Package.build gem_spec

          verbose trace do
            mv gem_file, '..'
          end
        end
      end
    end
  end

end

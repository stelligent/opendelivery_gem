#Copyright (c) 2014 Stelligent Systems LLC
#
#MIT LICENSE
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.

module OpenDelivery
  class SourceControl
    def initialize(dir)
      @dir = dir
    end

    def log(lines=10)
      Dir.chdir(@dir) do
        `git log --stat -n #{lines}`
      end
    end

    def status
      Dir.chdir(@dir) do
        `git status -sb`
      end
    end

    def remove_missing_files(status)
      removed_files = []
      files = find_removed_files(status)
      files.each do |file|
        Dir.chdir(@dir) do
          removed_files << `git rm -rf #{file}`
        end
      end
      removed_files
    end

    def add(files)
      Dir.chdir(@dir) do
        `git add #{files} -v`
      end
    end

    def commit(message)
      Dir.chdir(@dir) do
        `git commit -m "#{message}"`
      end
    end

    def push
      Dir.chdir(@dir) do
        `git push`
      end
    end

    def pull
      Dir.chdir(@dir) do
        @result = `git pull`
      end
      if $?.to_i != 0
        raise "Your pull failed. Probably because of a merge conflict!"
      end
      @result
    end

    def conflicted(status)
      status.each_line do |stat|
        if stat.match(/^UU /) || stat.match(/^U /) || stat.match(/^U /)
          raise "You have file conflicts when trying to merge. Because this could end up horribly, we won't try to automatically fix these conflicts. Please go an manually merge the files!"
        end
      end
    end

    protected


    def find_removed_files(status)
      statuses = []
      status.each_line do |stat|
        if stat.match(/^ D /)
          statuses << stat.split[1]
        end
      end
      statuses
    end
  end
end

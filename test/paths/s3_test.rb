require_relative '../test_helper'

module Paths
  class S3Test < Minitest::Test
    describe IOStreams::Paths::S3 do
      before do
        unless ENV['S3_BUCKET_NAME']
          skip "Supply 'S3_BUCKET_NAME' environment variable with S3 bucket name to test S3 paths"
        end
      end

      let :file_name do
        File.join(File.dirname(__FILE__), 'files', 'text.txt')
      end

      let :raw do
        File.read(file_name)
      end

      let(:root_path) { IOStreams::Paths::S3.new("s3://#{ENV['S3_BUCKET_NAME']}/iostreams_test") }

      let :existing_path do
        path = root_path.join('test.txt')
        path.write(raw) unless path.exist?
        path
      end

      let :missing_path do
        root_path.join('unknown.txt')
      end

      let :write_path do
        root_path.join('writer_test.txt').delete
      end

      describe '#delete' do
        it 'existing file' do
          assert existing_path.delete.is_a?(IOStreams::Paths::S3)
        end

        it 'missing file' do
          assert missing_path.delete.is_a?(IOStreams::Paths::S3)
        end
      end

      describe '#exist?' do
        it 'existing file' do
          assert existing_path.exist?
        end

        it 'missing file' do
          refute missing_path.exist?
        end
      end

      describe '#mkpath' do
        it 'returns self for non-existant path' do
          assert existing_path.mkpath.is_a?(IOStreams::Paths::S3)
        end

        it 'checks for lack of existence' do
          assert missing_path.mkpath.is_a?(IOStreams::Paths::S3)
        end
      end

      describe '#mkdir' do
        it 'returns self for non-existant path' do
          assert existing_path.mkdir.is_a?(IOStreams::Paths::S3)
        end

        it 'checks for lack of existence' do
          assert missing_path.mkdir.is_a?(IOStreams::Paths::S3)
        end
      end

      describe '#reader' do
        it 'reads' do
          assert_equal raw, existing_path.reader { |io| io.read }
        end
      end

      describe '#size' do
        it 'existing file' do
          assert_equal raw.size, existing_path.size
        end

        it 'missing file' do
          assert_nil missing_path.size
        end
      end

      describe '#writer' do
        it 'writes' do
          assert_equal raw.size, write_path.writer { |io| io.write(raw) }
          assert write_path.exist?
          assert_equal raw, write_path.read
        end
      end

      describe '#each_child' do
        # TODO: case_sensitive: false, directories: false, hidden: false
        let(:files_for_test) { %w[abd/test1.txt xyz/test2.csv abd/test5.file] }

        let :multiple_paths do
          files_for_test.collect { |file_name| root_path.join(file_name) }
        end

        let :write_raw_data do
          multiple_paths.each { |path| path.write(raw) }
        end

        it 'existing file returns just the file itself' do
          # Glorified exists call
          assert_equal [existing_path.to_s], existing_path.children
        end

        it 'returns all the children' do
          write_raw_data
          # Glorified exists call
          assert_equal [existing_path.to_s], existing_path.children
        end

        it 'missing path' do
          count = 0
          missing_path.each { |_| count += 1 }
          assert_equal 0, count
        end
      end
    end
  end
end
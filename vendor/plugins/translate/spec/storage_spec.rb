require File.dirname(__FILE__) + '/spec_helper'

describe Translate::Storage do
  describe "get translation origin filename" do
    before(:each) do
      @storage = Translate::Storage.new(:en)
    end
    after(:each) do
      files_path(:es).each { |path| FileUtils.rm(path) rescue nil }
    end

    it "should read the origin file name" do
      I18n.backend.load_translations(*files_path)
      @storage.should_receive(:get_translation_origin_filename).and_return(files_path.last)
      @storage.get_translation_origin_filename('article.title')
    end

    it "should raise an error for unexistent localization" do
      I18n.backend.load_translations(*files_path)
      @storage.should_receive(:get_translation_origin_filename).with('article.invented.title').should raise_error
      @storage.get_translation_origin_filename('article.invented.title')
    end

    it "should get origin filename from a existent translation" do
      I18n.backend.load_translations(*files_path)
      @storage = Translate::Storage.new(:es)
      @storage.should_receive(:get_translation_origin_filename).and_return(files_path(:es).last)
      @storage.get_translation_origin_filename('article.title')
    end

  end
  describe "write_to_file" do
    before(:each) do
      @storage = Translate::Storage.new(:en)
    end
    after(:each) do
      files_path(:es).each { |path| FileUtils.rm(path) rescue nil }
    end

    it "writes all I18n messages for a locale to YAML files" do
      # Initialize storage to translate to spanish applying the configuration

      Translate::Storage.mode = :origin
      # Load each yml sample
      files_path(:en).each { |path| I18n.backend.load_file(path) }

      keys = {'application.app_name' => "One Application Translated"}
      deep_existing_keys = { "en" => {
          "application"  =>  {
            "existing_translations" => 'value'
          }
        }
      }
      deep_combined_keys = { "en" => {
          "application"  =>  {
            "existing_translations" => 'value',
            "app_name" => "One Application Translated"
          }
        }
      }

      YAML.stub!(:load_file).and_return(deep_existing_keys)

      @storage.stub!(:decide_filenames).and_return([files_path(:es).first])
      @storage.should_receive(:decide_filenames).once.and_return([files_path(:es).first])

      # Mock the file and check the expectante on the final value that will be saved to disk
      file = mock(:file)
      file.should_receive(:write).with(deep_combined_keys).once

      Translate::File.should_receive(:new).once.and_return(file)

      @storage.write_to_file(keys)
    end
  end
  describe "find_or_create_origin_filename" do
    before(:each) do
      @storage = Translate::Storage.new(:en)
    end
    after(:each) do
      files_path(:es).each { |path| FileUtils.rm(path) rescue nil }
    end

    it "replace a existing path" do
      File.stub!(:exists?).and_return(true)
      @storage.find_or_create_origin_filename(
        'config/locales/es/exists/translations.yml', 'es'
      ).should == 'config/locales/en/exists/translations.yml'
    end

    it "replace a non existing path creating it" do
      File.stub!(:exists?).and_return(false)
      File.stub!(:dirname).and_return('foo')
      FileUtils.stub!(:mkdir_p).and_return(false)

      file = mock(:file)
      Translate::File.stub!(:new).and_return(file)

      file.should_receive(:write).with({"en" => {}}).once
      @storage.find_or_create_origin_filename('config/locales/es/exists/translations.yml', 'es')
    end
  end

  describe "decide_filenames" do
    before(:each) do
      @storage = Translate::Storage.new(:en)
    end
    after(:each) do
      files_path(:es).each { |path| FileUtils.rm(path) rescue nil }
    end

    it "returns the log backup file path and the dump file as the mode is application" do
       Translate::Storage.mode = :application

      @storage.should_not_receive(:find_or_create_origin_filename)
      File.stub!(:exists?).and_return(true)
      @storage.should_not_receive(:create_empty_translations_file)
      @storage.should_receive(:log_file_path).and_return("/log_file_path")

      assert_equal [@storage.application_mode_file_path, "/log_file_path"],
                    @storage.decide_filenames("not_important.key")
    end

    # dump_file = application_mode_file_path
    it "returns the log backup file path and the dump file as the mode is application the dump file didn't exist" do
      Translate::Storage.mode = :application

      @storage.should_not_receive(:find_or_create_origin_filename)
      File.stub!(:exists?).and_return(false)
      @storage.should_receive(:create_empty_translations_file).
                with(@storage.application_mode_file_path)
      @storage.should_receive(:log_file_path).and_return("/log_file_path")

      assert_equal [@storage.application_mode_file_path, "/log_file_path"],
                    @storage.decide_filenames("not_important.key")
    end

    it "returns the log backup file path, the dump file and the origin file name as the mode is origin" do
      Translate::Storage.mode = :origin

      @storage.stub!(:get_translation_origin_filename).and_return(["path", "es"])
      @storage.should_receive(:find_or_create_origin_filename).with("path", "es").
        and_return("origin_path")

      File.stub!(:exists?).and_return(true)
      @storage.should_not_receive(:create_empty_translations_file)
      @storage.should_receive(:log_file_path).and_return("/log_file_path")
      @storage.stub!(:replace_external_to_application_file_paths).and_return("path")

      assert_equal ["origin_path", @storage.application_mode_file_path, "/log_file_path"],
                    @storage.decide_filenames("not_important.key")
    end

    it "returns the log backup file path, the dump file and the origin file name as the mode is origin and
    the translation existed" do
      Translate::Storage.mode = :origin

      @storage.stub!(:get_translation_origin_filename).and_return(["path", "en"])
      @storage.should_not_receive(:find_or_create_origin_filename)

      File.stub!(:exists?).and_return(true)
      @storage.should_not_receive(:create_empty_translations_file)
      @storage.should_receive(:log_file_path).and_return("/log_file_path")
      @storage.stub!(:replace_external_to_application_file_paths).and_return("path")

      assert_equal ["path", @storage.application_mode_file_path, "/log_file_path"],
                    @storage.decide_filenames("not_important.key")
    end

    it "returns the log backup file path, the dump file and the path to external application files for english" do
      Translate::Storage.mode = :origin


      @storage.stub!(:get_translation_origin_filename).and_return(["/tmp/path_to_file_external_to_the_project", "en"])
      File.stub!(:exists?).and_return(true)
      
      assert @storage.decide_filenames("not_important.key").first.include?(
        "/config/locales/application_external_en.yml.commit")
                    
    end
  end
  
  describe "init_translations_and_ignore_app_mode_file_dump" do
    before(:each) do
      @storage = Translate::Storage.new(:en)
    end
    after(:each) do
      files_path(:es).each { |path| FileUtils.rm(path) rescue nil }
    end

    it "reset the files sorting and refusing dump files" do
    end
  end

  def files_path locale = :en
    [File.join(File.dirname(__FILE__), "files", "translate", "config", "locales", "#{locale}", "app.yml"),
      File.join(File.dirname(__FILE__), "files", "translate", "config", "locales", "#{locale}.yml")]
  end
end

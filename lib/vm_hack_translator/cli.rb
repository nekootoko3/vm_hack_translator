require "vm_hack_translator/parser"
require "vm_hack_translator/command_type"
require "vm_hack_translator/code_writer"

module VmHackTranslator::Cli
  def self.start(args)
    input_files = case File.ftype(args[0])
      when "file"
        raise "Invalid file type passed" unless args[0].match?(/.+\.vm/)

        [args[0]]
      when "directory"
        Dir.glob("#{args[0]}/*.vm")
      else
        raise "Invalid input specified"
      end
    raise "Valid input files don't exist" if input_files.empty?

    code_writer = VmHackTranslator::CodeWriter.new(args[1])

    input_files.each do |input_file|
      parser = VmHackTranslator::Parser.new(input_file)
      code_writer.set_file_name(input_file)
      while parser.has_more_commands?
        parser.advance!

        case parser.command_type
        when VmHackTranslator::CommandType::C_PUSH, VmHackTranslator::CommandType::C_POP
          code_writer.write_push_pop!(parser.command_type, parser.arg1, parser.arg2.to_i)
        when VmHackTranslator::CommandType::C_ARITHMETIC
          code_writer.write_arithmetic!(parser.arg1)
        when VmHackTranslator::CommandType::C_LABEL
          code_writer.write_label!(parser.arg1)
        when VmHackTranslator::CommandType::C_IF_GOTO
          code_writer.write_if!(parser.arg1)
        when VmHackTranslator::CommandType::C_GOTO
          code_writer.write_goto!(parser.arg1)
        when VmHackTranslator::CommandType::C_FUNCTION
          code_writer.write_function!(parser.arg1, parser.arg2.to_i)
        when VmHackTranslator::CommandType::C_RETURN
          code_writer.write_return!
        when VmHackTranslator::CommandType::C_CALL
          code_writer.write_call!(parser.arg1, parser.arg2.to_i)
        else
        end
      end
    end

    code_writer.close!
  end
end

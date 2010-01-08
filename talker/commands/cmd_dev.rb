module Commands
  define_command 'reboot' do
    if developer?
      reboot
    else
      output "No permission."
    end
  end
end
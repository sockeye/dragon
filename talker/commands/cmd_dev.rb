module Commands
  define_command 'reboot' do
    if developer?
      reboot
    else
      output "No permission."
    end
  end
  
  define_command 'multis' do
    output title_line("Multis") + "\n" + Multi.view + "\n" + blank_line
  end
end
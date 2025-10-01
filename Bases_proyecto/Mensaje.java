import javax.swing.JOptionPane;

public class Mensaje {
    
    public static void main(String[] args) {
        // Verificar que hay argumentos
        if (args.length == 0) {
            System.err.println("Error: No se proporcionaron argumentos");
            System.exit(1);
        }
        
        String comando = args[0];
        
        // Caso 1: Solo mostrar mensaje (show_message desde Elixir)
        if (args.length == 1) {
            
            showMessage(comando);
        }
        // Caso 2: Input con tipo (input desde Elixir)
        else if (args.length == 3 && "input".equals(comando)) {
            String mensaje = args[1];
            String tipo = args[2];
            String resultado = input(mensaje, tipo);
            System.out.print(resultado); 
        }
        else {
            System.err.println("Error: Argumentos inválidos");
            System.exit(1);
        }
    }
    
    public static void showMessage(String message) {
        JOptionPane.showMessageDialog(null, message, "Mensaje", JOptionPane.INFORMATION_MESSAGE);
    }
    

    public static String input(String message, String type) {
        String input = null;
        boolean validInput = false;
        
        while (!validInput) {
            switch (type) {
                case ":string":
                    input = inputString(message);
                    validInput = (input != null && !input.trim().isEmpty());
                    if (!validInput) {
                        JOptionPane.showMessageDialog(null, "Debe ingresar un texto válido", "Error", JOptionPane.ERROR_MESSAGE);
                    }
                    break;
                    
                case ":integer":
                    input = inputInteger(message);
                    validInput = (input != null);
                    break;
                    
                case ":float":
                    input = inputFloat(message);
                    validInput = (input != null);
                    break;
                    
                default:
                    JOptionPane.showMessageDialog(null, "Tipo no soportado: " + type, "Error", JOptionPane.ERROR_MESSAGE);
                    System.exit(1);
            }
        }
        
        return input;
    }
    

    private static String inputString(String message) {
        String input = JOptionPane.showInputDialog(null, message, "Entrada de Texto", JOptionPane.QUESTION_MESSAGE);
        
    
        if (input == null) {
            System.exit(0);
        }
        
        return input;
    }
    

    private static String inputInteger(String message) {
        while (true) {
            String input = JOptionPane.showInputDialog(null, message, "Entrada de Número Entero", JOptionPane.QUESTION_MESSAGE);
            
            // Si el usuario canceló, salir
            if (input == null) {
                System.exit(0);
            }
            
            try {
                Integer.parseInt(input.trim());
                return input.trim();
            } catch (NumberFormatException e) {
                JOptionPane.showMessageDialog(null, "Debe ingresar un número entero válido", "Error", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    
    /**
     * Solicita un número decimal usando JOptionPane con validación
     */
    private static String inputFloat(String message) {
        while (true) {
            String input = JOptionPane.showInputDialog(null, message, "Entrada de Número Decimal", JOptionPane.QUESTION_MESSAGE);
            
            // Si el usuario canceló, salir
            if (input == null) {
                System.exit(0);
            }
            
            try {
                Double.parseDouble(input.trim());
                return input.trim();
            } catch (NumberFormatException e) {
                JOptionPane.showMessageDialog(null, "Debe ingresar un número decimal válido (use punto como separador)", "Error", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
}

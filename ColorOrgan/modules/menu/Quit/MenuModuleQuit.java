package modules.menu.Quit;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

public class MenuModuleQuit extends PluginModule {
    private ActionListener menuAction = new ActionListener() {
        @Override
        public void actionPerformed (ActionEvent e) {
            System.exit(0);
        }
    };

    private String name = "Quit";

    private ModuleType moduleType = PluginModule.ModuleType.MENUOPTION;

    public MenuModuleQuit () {

    }

    public boolean setup () {
        return true;
    }

    public boolean loop () {
        return true;
    }

    public boolean stop () {
        return true;
    }

    public ActionListener getMenuAction () {
        return menuAction;
    }

    public String getName () {
        return name;
    }

    public ModuleType getModuleType () {
        return moduleType;
    }
}

package modules.modes.Rainbow;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.CheckboxMenuItem;

public class MenuModuleRainbow extends PluginModule {
    private ActionListener menuAction = new ActionListener() {
        @Override
        public void actionPerformed (ActionEvent e) {
            CheckboxMenuItem mi = (CheckboxMenuItem) e.getSource();
            System.out.println("Rainbow plugin toggling");
            if (mi.getState()) {
                System.out.println("Rainbow plugin enabled");
            } else {
                System.out.println("Rainbow plugin disabled");
            }
        }
    };

    private String name = "Rainbow";

    private ModuleType moduleType = PluginModule.ModuleType.MODE;

    public MenuModuleRainbow () {

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

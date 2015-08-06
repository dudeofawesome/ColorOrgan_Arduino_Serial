package modules.plugins.Hangouts;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.CheckboxMenuItem;

public class MenuModuleHangouts extends PluginModule {
    private ActionListener menuAction = new ActionListener() {
        @Override
        public void actionPerformed (ActionEvent e) {
            CheckboxMenuItem mi = (CheckboxMenuItem) e.getSource();
            System.out.println("Hangouts plugin toggling");
            if (mi.getState()) {
                System.out.println("Hangouts plugin enabled");
            } else {
                System.out.println("Hangouts plugin disabled");
            }
        }
    };

    private String name = "Hangouts";

    private ModuleType moduleType = PluginModule.ModuleType.PLUGIN;

    public MenuModuleHangouts () {

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

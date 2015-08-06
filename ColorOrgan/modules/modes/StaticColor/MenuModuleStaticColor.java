package modules.modes.StaticColor;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.CheckboxMenuItem;

public class MenuModuleStaticColor extends PluginModule {
    private ActionListener menuAction = new ActionListener() {
        @Override
        public void actionPerformed (ActionEvent e) {
            CheckboxMenuItem mi = (CheckboxMenuItem) e.getSource();
            System.out.println("StaticColor plugin toggling");
            if (mi.getState()) {
                System.out.println("StaticColor plugin enabled");
            } else {
                System.out.println("StaticColor plugin disabled");
            }
        }
    };

    private String name = "StaticColor";

    private ModuleType moduleType = PluginModule.ModuleType.MODE;

    public MenuModuleStaticColor () {

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

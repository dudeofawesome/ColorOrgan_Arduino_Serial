package modules.modes.StaticColor;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

public abstract class PluginModule {
    private ActionListener menuAction = new ActionListener() {
        @Override
        public void actionPerformed (ActionEvent e) {

        }
    };
    private String name = "null";
    private ModuleType moduleType = null;

    public static enum ModuleType {
        PLUGIN,
        MODE,
        MENUOPTION
    }

    public PluginModule () {

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

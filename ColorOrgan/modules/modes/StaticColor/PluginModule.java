package modules.modes.StaticColor;

import java.awt.event.ItemListener;
import java.awt.event.ItemEvent;

public abstract class PluginModule {
    private ItemListener menuAction = new ItemListener() {
        @Override
        public void itemStateChanged (ItemEvent e) {

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

    public ItemListener getMenuAction () {
        return menuAction;
    }

    public String getName () {
        return name;
    }

    public ModuleType getModuleType () {
        return moduleType;
    }
}

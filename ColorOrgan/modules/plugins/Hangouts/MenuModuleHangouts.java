package modules.plugins.Hangouts;

import java.awt.event.ItemListener;
import java.awt.event.ItemEvent;
import java.awt.CheckboxMenuItem;

public class MenuModuleHangouts extends PluginModule {
    private ItemListener menuAction = new ItemListener() {
        @Override
        public void itemStateChanged (ItemEvent e) {
            if (e.getStateChange() == e.SELECTED) {
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

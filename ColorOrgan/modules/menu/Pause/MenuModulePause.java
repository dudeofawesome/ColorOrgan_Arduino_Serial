package modules.menu.Pause;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.MenuItem;
import java.awt.Image;
import java.awt.TrayIcon;

public class MenuModulePause extends PluginModule {
    public TrayIcon _trayIcon_;
    public Image _runningImage_;
    public Image _stoppedImage_;

    private ActionListener menuAction = new ActionListener() {
        @Override
        public void actionPerformed (ActionEvent e) {
            MenuItem mi = (MenuItem) e.getSource();
            if (mi.getLabel().equals("Pause")) {
                mi.setLabel("Unpause");
                _trayIcon_.setImage(_stoppedImage_);
            } else {
                mi.setLabel("Pause");
                _trayIcon_.setImage(_runningImage_);
            }
        }
    };

    private String name = "Pause";

    private ModuleType moduleType = PluginModule.ModuleType.MENUOPTION;

    public MenuModulePause () {

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

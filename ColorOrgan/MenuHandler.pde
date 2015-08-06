import java.awt.TrayIcon;
import java.net.URL;
import java.net.URLClassLoader;
import java.net.MalformedURLException;
import java.util.Arrays;
import java.lang.reflect.Method;
import java.lang.reflect.Field;
import java.awt.event.ActionListener;
import java.awt.event.ItemListener;

class MenuHandler {
  final Image runningImage = loadImage("./ic_play_circle_filled_black.png").getImage();
  final Image stoppedImage = loadImage("./ic_pause_circle_filled_black.png").getImage();

  TrayIcon trayIcon = new TrayIcon(runningImage);

  PopupMenu trayMenu = new PopupMenu();

  HashMap<String, Object> fillableFields = new HashMap<String, Object>();

  public MenuHandler () {
    fillHashMap();
    loadMenu();
  }

  public void fillHashMap () {
    fillableFields.put("_trayIcon_", trayIcon);
    fillableFields.put("_runningImage_", runningImage);
    fillableFields.put("_stoppedImage_", stoppedImage);
  }

  public void loadMenu () {
    if (SystemTray.isSupported()) {
      SystemTray tray = SystemTray.getSystemTray();
      PopupMenu inputMenu = new PopupMenu("Audio Channel");
      trayMenu.add(inputMenu);
      PopupMenu modesMenu = new PopupMenu("Mode");
      trayMenu.add(modesMenu);
      PopupMenu pluginsMenu = new PopupMenu("Plugins");
      trayMenu.add(pluginsMenu);

      loadAudioChannels(inputMenu);
    //   loadFromLibrary("modes", modesMenu, true);
    //   loadFromLibrary("plugins", pluginsMenu, true);

      trayMenu.addSeparator();

      loadFromLibrary("menu", trayMenu, false);

      trayIcon.setImage(runningImage);
      trayIcon.setPopupMenu(trayMenu);
      try {
        tray.add(trayIcon);
      } catch (AWTException e) {
        System.err.println(e);
      }
    }
  }

  public void loadAudioChannels (PopupMenu menu) {
    CheckboxMenuItem inputStereo = new CheckboxMenuItem("Stereo Mix");
    inputStereo.setState(true);
    menu.add(inputStereo);
    CheckboxMenuItem inputMic = new CheckboxMenuItem("Microphone");
    menu.add(inputMic);
  }

  private void loadFromLibrary (String library, PopupMenu menu, boolean checkbox) {
      try {
        ClassLoader cl = new URLClassLoader(new URL[]{new File(sketchPath("")).toURL()});

        File folder = new File(sketchPath("") + "/modules/" + library + "/");
        File[] items = folder.listFiles();
        for (int i = 0; i < items.length; i++) {
          if (items[i].isDirectory()) {
            File pluginFolder = new File(sketchPath("") + "/modules/" + library + "/" + items[i].getName());
            if (pluginFolder.listFiles().length > 0) {
              String[] pluginItems = pluginFolder.list();
              if (Arrays.asList(pluginItems).contains("MenuModule" + items[i].getName() + ".class")) {
                Class<?> _class = cl.loadClass("modules." + library + "." + items[i].getName() + ".MenuModule" + items[i].getName());

                try {
                  Object obj = _class.newInstance();
                  Method getName = _class.getDeclaredMethod("getName");
                  Method getMenuAction = _class.getDeclaredMethod("getMenuAction");
                  Method getModuleType = _class.getDeclaredMethod("getModuleType");

                  insertRequestedFields(_class, obj);

                  try {
                    if (checkbox) {
                      CheckboxMenuItem menuItem = new CheckboxMenuItem(getName.invoke(obj).toString());
                      menuItem.addItemListener((ItemListener) getMenuAction.invoke(obj));
                      menu.add(menuItem);
                    } else {
                      MenuItem menuItem = new MenuItem(getName.invoke(obj).toString());
                      menuItem.addActionListener((ActionListener) getMenuAction.invoke(obj));
                      menu.add(menuItem);
                    }
                  } catch (java.lang.reflect.InvocationTargetException e) {println(e);}
                } catch (InstantiationException e) {println(e);} catch (IllegalAccessException e) {println(e);} catch (NoSuchMethodException e) {println(e);}
              }
            }
          }
        }
      } catch (MalformedURLException e) {} catch (ClassNotFoundException e) {println(e);}
  }

  private void insertRequestedFields (Class<?> cl, Object obj) {
    ArrayList<Field> fieldsToFill = new ArrayList<Field>();
    Field[] fields = cl.getFields();
    for (int i = 0; i < fields.length; i++) {
      if (fields[i].getName().startsWith("_") && fields[i].getName().endsWith("_")) {
        fieldsToFill.add(fields[i]);
      }
    }
    for (Field field: fieldsToFill) {
      try {
        println("setting " + field.getName());
        field.set(obj, fillableFields.get(field.getName()));
        println(fillableFields.get(field.getName()) + " = " + field.get(obj));
      } catch (IllegalAccessException e) {println(e);}
    }
  }
}

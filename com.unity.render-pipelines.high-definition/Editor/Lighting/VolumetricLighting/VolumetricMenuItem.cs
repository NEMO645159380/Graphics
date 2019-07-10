using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering;

namespace UnityEditor.Rendering.HighDefinition
{
    public class VolumetricMenuItems
    {
        [MenuItem("GameObject/Rendering/Density Volume", priority = CoreUtils.gameObjectMenuPriority)]
        static void CreateDensityVolumeGameObject(MenuCommand menuCommand)
        {
            var parent = menuCommand.context as GameObject;
            var densityVolume = CoreEditorUtils.CreateGameObject(parent, "Density Volume");
            GameObjectUtility.SetParentAndAlign(densityVolume, menuCommand.context as GameObject);
            Undo.RegisterCreatedObjectUndo(densityVolume, "Create " + densityVolume.name);
            Selection.activeObject = densityVolume;

            densityVolume.AddComponent<DensityVolume>();
        }
    }
}

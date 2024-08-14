#!/bin/bash

# Configuración
PWD_=$(pwd);
PLUGIN_DIR="./"  # Directorio base para buscar el plugin
VERSION_REGEX="([0-9]+)\.([0-9]+)\.([0-9]+)(-[0-9]+)?"
LOG_FILE="update_plugin_log.txt"
PLUGIN_FILE=""
NAME_PLUGIN=$(basename "$PWD_");
PLUGIN_FILENAME=$NAME_PLUGIN".php";
# Función para registro
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Función para verificar la disponibilidad de commit (de la respuesta anterior)
function verificar_disponibilidad_commit() {
     # Verificar si hay archivos listos para commit (en el stage)
    if git diff --cached --quiet; then
        # Verificar si hay cambios no rastreados (no agregados al stage)
        if git diff-files --quiet --; then
            echo "No hay archivos para commit. Por favor, usa 'git add' para agregar archivos al stage."
            return 1
        fi
    fi

    echo "Todo listo para hacer commit."
    return 0
}


    verificar_disponibilidad_commit
    if [[ $? -ne 0 ]]; then
        exit 1
    fi


# Función para realizar un commit (de la respuesta anterior)
function realizar_commit() {
    local new_version=$1
    local numero_commit=$(date +%s)
    local mensaje_commit="Actualización desde updater - versión $new_version - commit $numero_commit - $(date '+%Y-%m-%d %H:%M:%S')"

    git add ${nombre_plugin}".php"
	git add"README.txt"
    git add "version.txt"

    git commit -m "$mensaje_commit"
    if [[ $? -eq 0 ]]; then
        echo "Commit realizado con éxito: $mensaje_commit"
    else
        echo "Error al realizar el commit"
        return 1
    fi
}


# Función para construir un "zip" usando Git
function construir_zip_con_git() {
    local nombre_plugin=$1
    local new_version=$2
	local tmp_dir=$(mktemp -d);
	local temp="${tmp_dir}/${nombre_plugin}"
    local destino="${tmp_dir}/${nombre_plugin}.zip"
	local rename="../${nombre_plugin}-v${new_version}.zip"
			
	$(mkdir -p ${temp});
	
    # Verificar si el directorio .git existe
    if [ ! -d ".git" ]; then
        echo "Error: Este directorio no es un repositorio Git."
        return 1
    fi

    # Crear el archivo tar.gz usando Git
    git archive --format=zip -o "$destino" HEAD
    if [[ $? -eq 0 ]]; then
		echo "archivo construido correctamente"
    else
        echo "Error al crear el archivo empaquetado"
        return 1
    fi
	if [ -d $directory ]; then 
		  echo "Directorio construido correctamente";
	fi 
	
	unziping=$(unzip "${destino}" -d "${temp}")
	if [ unziping ];then 
			echo "Descomprimido en directorio correctamente";
	fi 
	zipping=$(zip -r "${temp}" "${rename}")
	if [ zipping ];then 
			echo "Comprimido y empacado correctamente en $rename";
	fi 
}


# Función para convertir guiones a guiones bajos y a mayúsculas
convertir_a_mayusculas_y_guiones_bajos() {
    local cadena="$1"
    echo "${cadena//-/_}" | tr '[:lower:]' '[:upper:]'
}

# Función para capitalizar la primera letra de cada palabra, manteniendo guiones bajos
capitalizar_palabras() {
    local cadena="$1"
    local palabra=""
    for caracter in $(echo "$cadena" | sed 's/\(.\)/ \1/g'); do
        if [[ "$palabra" == "" ]]; then
            palabra="${caracter^^}"
        else
            palabra="${palabra}${caracter,,}"
        fi
    done
    echo "$palabra"
}

# Ejemplo de uso
string_package="$NAME_PLUGIN"
string_package_capitalizated=$(capitalizar_palabras "$cadena_original")

# Ejemplo de uso
cadena_original="$NAME_PLUGIN-version"
PLUGIN_VERSION_CONSTANT=$(convertir_a_mayusculas_y_guiones_bajos "$cadena_original")

# Función para actualizar la versión en example.php
update_version_constant() {
  local version="$1"
  local file="$PLUGIN_FILENAME"
  local version_file="version.txt"

  # Crear la nueva línea con la versión actualizada
  line_to_insert="define($PLUGIN_VERSION_CONSTANT, '$version');"
  echo "Constante a definir: "$line_to_insert;
  
  # Buscar la línea y reemplazar el valor
  # Archivo a modificar
    
    # Leer la nueva versión
    read version < "$version_file"

    # Crear la nueva línea con la versión actualizada
    line_to_insert="define(\'$PLUGIN_VERSION_CONSTANT\', \'$version\');"

    # Enumerar las líneas y buscar la línea a eliminar
    line_number=$(grep -n "$PLUGIN_VERSION_CONSTANT" "$file" | cut -d: -f1)

    # Si se encontró la línea, eliminar y insertar la nueva
    if [[ -n "$line_number" ]]; then

    nueva_linea=$line_to_insert;
    numero_linea=$line_number;
    if [[ -z "$numero_linea" || -z "$line_to_insert" || -z "$file" ]]; then
        echo "Error: Asegúrate de que todas las variables (numero_linea, line_to_insert, file) estén definidas."
    else
        # Ejecutar el comando sed
        sed -i "${numero_linea}s/.*/${line_to_insert}/" "$file"
        echo "Línea ${numero_linea} eliminada y nuevo contenido agregado."
    fi

    echo "Versión actualizada correctamente en $file"
    else
    echo "No se encontró la línea para actualizar la versión"
    fi
 
  # Verificar si se realizó el cambio (opcional)
  if grep -q "define($PLUGIN_VERSION_CONSTANT, '$version')" "$file"; then
    echo "Versión actualizada correctamente en $file"
  else
    echo "No se encontró la línea para actualizar la versión"
  fi
  
  # Convertir la versión a mayúsculas
  version=$(echo "$version" | tr '[:lower:]' '[:upper:]')

  # Línea de búsqueda (adaptar según tu archivo)
  search_line='@package\s*\s*\s*\s*\s*'$string_package_capitalizated;

  # Crear un archivo temporal
  tmpfile=$(mktemp)

  # Procesar el archivo example.php línea por línea
  while IFS= read -r line; do
    if [[ "$line" == "$search_line" ]]; then
      echo "$line" >> "$tmpfile"
      echo "$line_to_insert" >> "$tmpfile"
    else
      echo "$line" >> "$tmpfile"
    fi
  done < "$file"

  # Reemplazar el archivo original con el archivo temporal
  mv "$tmpfile" "$file"

  echo "Versión actualizada en $file"
}

# Función para incrementar versión (mejorada)
increment_version() {
    local version="$1"
    local new_version=""
    local major minor patch suffix

    if [[ ! "$version" =~ ^$VERSION_REGEX$ ]]; then
        log "Formato de versión inválido: $version"
        return 1
    fi

    major=${BASH_REMATCH[1]}
    minor=${BASH_REMATCH[2]}
    patch=${BASH_REMATCH[3]}
    suffix=${BASH_REMATCH[4]}

    if (( major < 1 )); then
        log "La versión principal debe ser al menos 1"
        return 1
    fi

    # Incrementar la versión
    if [[ -z "$suffix" ]]; then
        patch=$((patch + 1))
        new_version="$major.$minor.$patch"
    else
        suffix=${suffix#-}
        suffix=$((suffix + 1))
        new_version="$major.$minor.$patch-$suffix"
    fi

    echo "$new_version"
}

# Función para actualizar la versión y README (mejorada)
update_version() {
    local plugin_file="$1"
    local version_line=""
    local current_version=""
    local new_version=""

    # Verificar que el archivo contenga el comentario '@wordpress-plugin'
    if ! grep -q "@wordpress-plugin" "$plugin_file"; then
        log "Archivo de plugin inválido: falta el comentario '@wordpress-plugin'"
        return 1
    fi

    # Obtener la línea de versión actual
    version_line=$(grep -E "^\s*\* Version:" "$plugin_file")
    if [[ -z "$version_line" ]]; then
        log "No se pudo encontrar la línea de versión en el archivo $plugin_file"
        return 1
    fi

    current_version=$(echo "$version_line" | awk '{print $3}')
    if [[ -z "$current_version" ]]; then
        log "No se pudo extraer la versión actual del archivo $plugin_file"
        return 1
    fi

    log "Versión actual: $current_version"

    # Incrementar la versión
    new_version=$(increment_version "$current_version")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    log "Nueva versión: $new_version"
    
    if echo "$new_version" > "$PWD_/version.txt"; then
        echo "Nueva versión escrita correctamente a version.txt"
    else
        echo "Error al escribir la nueva versión en version.txt"
    fi

    update_version_constant "$new_version"
    # Reemplazar la versión en el archivo del plugin
    sed -i "s/\(Version:\s*\)$current_version/\1$new_version/" "$plugin_file"

    # Actualizar el archivo README.txt
    echo "== $new_version ==" >> README.txt
    echo "* Update current $current_version to $new_version\n" >> README.txt
	echo "* Issue news updates\n" >> README.txt


    # Ejemplo de uso de las funciones
    nombre_plugin=$NAME_PLUGIN  # Reemplaza esto por el nombre del plugin

   

    realizar_commit "$new_version"
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    construir_zip_con_git "$nombre_plugin" "$new_version"
    
}

# Iniciar el proceso de actualización
log "Iniciando el proceso de actualización del plugin."

# Buscar el archivo principal del plugin
PLUGIN_FILE=$(grep -rl "@wordpress-plugin" "$PLUGIN_DIR"$NAME_PLUGIN.php | head -n 1)
if [[ -z "$PLUGIN_FILE" ]]; then
    log "No se encontró un archivo principal de plugin con el comentario '@wordpress-plugin'."
    exit 1
fi



log "Archivo principal del plugin detectado: $PLUGIN_FILE"

# Actualizar la versión
update_version "$PLUGIN_FILE"

log "Proceso de actualización completado."

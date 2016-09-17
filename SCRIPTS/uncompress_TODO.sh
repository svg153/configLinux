#!/bin/bash

#Universal Decompress, Este Script sirve para descomprimir ficheros en diferentes formatos
#Copyright (C) 2013  Francisco Dominguez Lerma
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


nombre=$1
nombre_extension=${nombre#*.}
version=0.1



function mostrar() {

echo ------------------------------------
echo "Tipo de archivo: $nombre_extension"
echo ------------------------------------

echo ------------------------------------
echo "Nombre de archivo: $nombre"
echo ------------------------------------

}


function comprobar() {


	if [ $error == 0 ]; then
		echo
		echo -e "\e[32mArchivos extraidos con éxito :)"
		echo -e "\e[39m"
		echo
	elif [ -z "$nombre" ]; then
		echo Debes escribir un nombre de archivo, para mostrar la ayuda escriba "ud --help"
		exit

	elif ! [ -e "$nombre" ]; then
		echo El fichero $nombre no existe, para mostrar la ayuda escriba "ud --help"
		exit
	else
		echo
		echo -e "\e[31mError al extraer los archivos :("
		echo -e "\e[39m"
		echo
	fi


}

case $nombre_extension in

      *tar.gz)
		mostrar
		tar zxf "$nombre"
	        error=$?
	        comprobar;;
      *tar.bz2)
		mostrar
  	        tar jxvf "$nombre"
	        error=$?
	        comprobar;;
      *gz)
	  	mostrar
 	        gzip -d "$nombre"
	 	error=$?
		comprobar;;
      *bz2)
                mostrar
		bzip2 -d "$nombre" 
	        error=$?
	 	comprobar;;
      *rar)
                mostrar
	        unrar x "$nombre"
	        error=$?
	        comprobar;;
      *zip)
                mostrar
	        unzip "$nombre"
	        error=$?
	        comprobar;;
      *tar)
                mostrar
                tar -xvf "$nombre"
	        error=$?
	        comprobar;;
#En esta linea es donde se deben de añadir más opciones de la construcción case con la misma estructura que los demás para añadir más formatos para descomprimir
	        
      --help)
		echo
	        echo
	        echo ---------- Ayuda ----------
	        echo
	        echo Universal Decompress le sirve para descomprimir
	        echo archivos de forma sencilla e universal
		echo
		echo El único argumento necesario es el archivo a descomprimir
		echo
		echo Ejemplo: ud mis_fotos.tar.gz
		echo
		echo ---------------------------
		echo
		echo
		exit;;
      --version)
		echo ---------------------------
		echo "Version: $version"
		echo ---------------------------;;
      *)
		error=1
		comprobar
		echo -------------------------------
		echo Formato no valido
		echo -------------------------------
		echo
		echo
		echo Este script no entiende la extensión de archivo $nombre_extension
		echo
		echo Para mostrar la ayuda escriba "ud --help"
		echo
		echo;;
 esac

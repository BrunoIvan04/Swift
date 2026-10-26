import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt, matplotlib.dates as mdates
from matplotlib.patches import Patch
from datetime import date
D=lambda m,d: date(2026,m,d)
rows=[
 ("Base","Proyecto base: lista local, pruebas, persistencia",D(8,17),D(8,21),"done"),
 ("Análisis","Requerimientos y clasificación (PO)",D(10,26),D(10,26),"done"),
 ("Análisis","CI en macOS + pruebas de UI automatizadas",D(10,26),D(10,26),"done"),
 ("Diseño","Navegación, arquitectura, datos y prototipos",D(10,26),D(10,26),"done"),
 ("Construcción","Detalle, fecha límite y filtro (adelantado)",D(10,26),D(10,26),"done"),
 ("Pruebas","Corrección de defectos D-01 a D-05",D(10,26),D(10,26),"done"),
 ("Sprint 2","Revisión del sprint y ajustes de diseño",D(10,27),D(11,6),"prog"),
 ("Construcción","Proyecto Firebase + login y registro",D(11,9),D(11,13),"todo"),
 ("Construcción","Repositorio Firestore async + estados de carga",D(11,11),D(11,19),"todo"),
 ("Construcción","Migración de tareas locales a la nube",D(11,18),D(11,20),"todo"),
 ("Construcción","Recordatorios (notificaciones locales)",D(11,23),D(11,27),"todo"),
 ("Pruebas","Unitarias, UI y reglas de Firestore",D(11,23),D(12,1),"todo"),
 ("Integración","Integración final, video y entrega",D(11,30),D(12,4),"todo"),
]
col={"done":"#1F6E4A","prog":"#2F6DB5","todo":"#9AA5B1"}
lab={"done":"Completado","prog":"En curso","todo":"Planeado"}
fig,ax=plt.subplots(figsize=(11,5.2),dpi=180); n=len(rows)
for i,(f,t,a,b,st) in enumerate(rows):
    y=n-1-i; w=max((b-a).days+1,1.3)
    ax.barh(y,w,left=mdates.date2num(a),height=0.62,color=col[st],edgecolor="white")
ax.set_yticks(range(n)); ax.set_yticklabels([f"{r[0]} · {r[1]}" for r in rows][::-1],fontsize=8.5)
ax.axvspan(mdates.date2num(D(8,22)),mdates.date2num(D(10,26)),color="#ECEFF1",zorder=0)
ax.text(mdates.date2num(D(9,23)),n-1.4,"Pausa sin commits\n(22 ago – 25 oct)",ha="center",fontsize=8.5,color="#555")
for a,b,lbl in [(D(10,26),D(11,6),"Sprint 2"),(D(11,9),D(11,20),"Sprint 3"),(D(11,23),D(12,4),"Sprint 4")]:
    ax.axvspan(mdates.date2num(a),mdates.date2num(b)+1,color="#E4ECF7",alpha=.45,zorder=0)
    ax.text(mdates.date2num(a)+ (b-a).days/2,n-0.25,lbl,ha="center",fontsize=8,color="#2F4F7F",fontweight="bold")
ax.axvline(mdates.date2num(D(10,26)),color="#C0392B",lw=1.1,ls="--")
ax.xaxis_date(); ax.xaxis.set_major_locator(mdates.WeekdayLocator(byweekday=0))
ax.xaxis.set_major_formatter(mdates.DateFormatter("%d/%m")); plt.setp(ax.get_xticklabels(),rotation=90,fontsize=7.5)
ax.set_xlim(mdates.date2num(D(8,14)),mdates.date2num(D(12,7))); ax.set_ylim(-0.7,n+0.4)
for sp in ["top","right"]: ax.spines[sp].set_visible(False)
ax.legend(handles=[Patch(color=col[k],label=lab[k]) for k in col],loc="lower left",fontsize=8,frameon=False,ncol=3,bbox_to_anchor=(0,-0.24))
ax.set_title("Cronograma — Mis tareas (línea roja: 26/10/2026)",fontsize=10.5,loc="left")
plt.tight_layout(); plt.savefig("img/gantt.png")

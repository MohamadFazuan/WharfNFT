import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { HomeComponent } from "./components/home/home.component";
import { CreateComponent } from "./components/create/create.component";
import { SwapComponent } from "./components/swap/swap.component";
import { MyImagesComponent } from './components/my-images/my-images.component';
import { ConnectComponent } from './components/connect/connect.component';
import { CreateCollectionComponent } from './components/create-collection/create-collection.component';

const routes: Routes = [
  {'path': '', redirectTo: 'home', pathMatch: 'full'},
  {'path': 'home', component: HomeComponent},
  {'path': 'swap', component: SwapComponent},
  {'path': 'myimages', component: MyImagesComponent},
  {'path': 'create', component: CreateComponent},
  {'path': 'connect', component: ConnectComponent},
  {'path': 'create_collection', component: CreateCollectionComponent}
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }

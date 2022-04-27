import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { HomeComponent } from './components/home/home.component';
import { MatToolbarModule } from "@angular/material/toolbar";
import { HttpClientModule } from "@angular/common/http";
import { ReactiveFormsModule } from "@angular/forms";
import { MatFormFieldModule } from "@angular/material/form-field";
import { MatIconModule } from "@angular/material/icon";
import { MatInputModule } from "@angular/material/input";
import { MatButtonModule } from "@angular/material/button";
import { MatCardModule } from "@angular/material/card";
import { MatSelectModule } from '@angular/material/select';
import { SwapComponent } from './components/swap/swap.component';
import { CreateComponent } from './components/create/create.component';
import { MyImagesComponent } from './components/my-images/my-images.component';
import { ConnectComponent } from './components/connect/connect.component';
import { CreateCollectionComponent } from './components/create-collection/create-collection.component';


@NgModule({
  declarations: [
    AppComponent,
    HomeComponent,
    SwapComponent,
    CreateComponent,
    MyImagesComponent,
    ConnectComponent,
    CreateCollectionComponent,
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    HttpClientModule,
    ReactiveFormsModule,
    NoopAnimationsModule,
    MatToolbarModule,
    MatFormFieldModule,
    MatIconModule,
    MatInputModule,
    MatButtonModule,
    MatCardModule,
    MatSelectModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule {
}

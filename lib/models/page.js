"use client";
import {useState} from 'react';
import Image from "next/image";
import ServiceCard from "../../components/ServiceCard";

export default function Home() {

  const services = [
    {id:1, title:"Yoga classes", price:"500", provider:"Anjali"},
    {id:2, title:"Laptop repair", price:"1000", provider:"Rahul"},
    {id:3, title:"Home cleaning", price:"800", provider:"Sunita"},
    {id:4, title:"Dog walking", price:"300", provider:"Vijay"}
  ];

  const [allServices, setAllServices] = useState(services);
  const [formData, setFormData] = useState({title:"", price:"", provider:""});  

  const addService = () => {
    const newService = {
      id: allServices.length + 1,
      title: formData.title,
      price: formData.price,
      provider: formData.provider
    };
    setAllServices([...allServices, newService]);
    setFormData({title:'',price:'', provider:''})
  };

    const updateService = (id, updatedData)=>{
      const updatedList = allServices.map(service =>
        service.id === id ? {...service, ...updatedData} : service
      );
      setAllServices(updatedList);
    }

  // The .filter() method creates a new array with all elements that pass the test implemented by the provided function.
  // In this context, .filter() loops through allServices and only keeps those where the service id does NOT match the id to delete.
  // This effectively removes (filters out) the targeted service from the list.
  //
  // Difference between .filter() and .map():
  // - .filter() returns only the elements for which the callback returns true (removes unwanted items).
  // - .map() transforms each element in the array and returns a new array of the same length (doesn't remove or add, just changes each item).
  //
  // Here, we use .filter() to remove a service; if we used .map(), the length would never decrease, and no elements would be removed.

  const deleteService = (id) => {
    const updatedList = allServices.filter(service => service.id !== id);
    setAllServices(updatedList);
  }

  return (
    <div className="flex min-h-screen bg-gradient-to-br from-blue-50 via-white to-blue-100 dark:from-gray-900 dark:via-black dark:to-blue-950 font-sans">
      <main className="flex flex-col items-center justify-center w-full max-w-2xl mx-auto py-24 px-6 bg-white/90 dark:bg-zinc-900/90 rounded-3xl shadow-xl">
        <Image
          src="/logo-neighbornode.svg"
          alt="NeighborNode logo"
          width={72}
          height={72}
          className="mb-6 rounded-xl shadow-md dark:bg-zinc-800"
          priority
        />
        
        <h1 className="text-5xl sm:text-6xl font-extrabold text-blue-700 dark:text-blue-400 tracking-tight text-center mb-2">
          NeighborNode
        </h1>
        <p className="text-lg sm:text-xl text-zinc-600 dark:text-zinc-200 text-center mb-8 max-w-xl">
          Connect with your local community and offer help, skills, and services. Discover and support your neighbors—together we build a stronger neighborhood.
        </p>
        <button 
        onClick={addService} 
        className="inline-block px-8 py-4 bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white text-lg font-semibold rounded-full shadow-lg transition-colors duration-200 mb-3">
            Post a Service
        </button>
        
      </main>

      <div className='w-full max-w-4xl mx-auto mt-12'>
        <div className="p-10 bg-gray-50 border-b">
          <h2 className="text-xl font-bold mb-4">Post a New Service</h2>
          <div className="flex flex-wrap gap-4">
            <input 
              type="text" 
              placeholder="Service Title" 
              className="border p-2 rounded"
              value={formData.title}
              onChange={(e) => setFormData({...formData, title: e.target.value})}
            />
            <input 
              type="number" 
              placeholder="Price" 
              className="border p-2 rounded"
              value={formData.price}
              onChange={(e) => setFormData({...formData, price: e.target.value})}
            />
            <input 
              type="text" 
              placeholder="Your Name" 
              className="border p-2 rounded"
              value={formData.provider}
              onChange={(e) => setFormData({...formData, provider: e.target.value})}
            />
            <button 
              onClick={addService}
              className="bg-blue-600 text-white px-6 py-2 rounded font-bold"
            >
              Confirm Post
            </button>
          </div>
        </div>
      </div>
      
      {/* 
        In JavaScript, the `.map()` function is an array method that creates a new array 
        by applying a callback function to each element of an existing array. It transforms 
        every item in the array according to the logic you provide in the callback and 
        returns the new array of transformed items.

        Here specifically, `allServices.map(...)` is used to generate a list of `ServiceCard` 
        React components. For each `service` object in the `allServices` array, the map function 
        returns a new `ServiceCard` component with the appropriate props (like `title`, `price`, 
        `provider`, and a unique `key`). This is a common React pattern to render a list of 
        components based on an array of data.
      */}

      <div className="max-w-6xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-6 p-10">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 p-10">
          {allServices.map((service) => (
            <ServiceCard 
              key={service.id} 
              title={service.title} 
              price={service.price} 
              provider={service.provider} 
              onDelete={()=> deleteService(service.id)}
              onUpdate = {(updatedData)=> updateService(serive.id, updatedData)}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
